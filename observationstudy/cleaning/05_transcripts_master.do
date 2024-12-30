//----------------------------------------------------------------------------//
// Stores text as stata dataset. Preserving all line breaks and text structure
//----------------------------------------------------------------------------//
clear all 
version 18

* Set up directories 
local office 0
if `office' == 1 {
	global root 	"C:/Users/cns8vg"
	global code 	"GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results"

}
if `office' == 0 {
	global root 	"/Users/steffenerickson"
	global code 	"Documents/GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results" 
}

//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
// Pulling txt files into stata 
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

*mvgstudy command 
include "${programs}/mvgstudy.ado"

* Text processing function 
include "${programs}/import_text_files_mata_function.do"
do "${root}/${code}/00_direct_observation_list.do"

* structure text data for import
cd "${root}/${data}/${transcripts}"
capture erase "${root}/${output}/transcripts_freeformat_outputfile.txt"
mata: driver("*.txt","${root}/${output}/transcripts_freeformat_outputfile.txt") // text processing function 

*import to stata
mkf transcripts
frame transcripts: infile strL filename strL text using "${root}/${output}/transcripts_freeformat_outputfile.txt"

*Split and clean 
frame transcripts: do "${root}/${code}/07_clean_transcripts.do"

* Merge observation Scores 
mkf obsrubric 
frame obsrubric : use "${root}/${data}/${cleandata}/obsrubric.dta" , clear 
frame copy transcripts transcripts_obsrubric , replace
frame transcripts_obsrubric: do "${root}/${code}/08_merge_directobs.do"
frame transcripts_obsrubric: save "${root}/${data}/${cleandata}/transcripts_obsrubric.dta" , replace

/*
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
// Using Python In Stata 
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

* Pull into Python 
local varlist filename text
python: from sfi import Data
python: import pandas as pd
python: df =  pd.DataFrame(Data.get('`varlist''))
python: transcript37 = df.iloc[36, 1]
python: print(transcript37.replace('\\n', '\n'))
python: df.head(5)

* or 
save "${root}/${output}/data.dta" , replace
python: import pandas as pd
python: path = 'C:/Users/cns8vg/Desktop'
python: df = pd.read_stata(f'{path}/data.dta')
python: first_row_second_column = df.iloc[36, 1]
python: print(first_row_second_column.replace('\\n', '\n'))


* Full Python Routine 

//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//
// Start Python Code 
//----------------------------------------------------------------------------//
//----------------------------------------------------------------------------//

local varlist filename text
python:

#Packages 
import pandas as pd
import numpy as np 
import re
import nltk
nltk.download('punkt_tab')
nltk.download('averaged_perceptron_tagger_eng')
from sfi import Data

# -----------------------------------------------------------------------------#
# Split transcripts into lines 
# -----------------------------------------------------------------------------#

df =  pd.DataFrame(Data.get('`varlist''))
df.columns = ['filename','text']
df_lines_split = df['text'].str.split(r'\\n').apply(pd.Series).stack().to_frame('line_str')
df_lines_split.reset_index(drop=True, inplace=True)
df_lines_split['filename'] = df['filename'].repeat(df_lines_split.shape[0] // len(df)).reset_index(drop=True)
df_cleaned = df_lines_split[df_lines_split['line_str'].str.strip() != ""]

# -----------------------------------------------------------------------------#
#  Filter out uneeded lines and expand lines to sentences
# -----------------------------------------------------------------------------#

# These functions find specific lines within each transcript
def is_teacher_timestamp(text):
    return bool(re.search(r'teacher \d+.*\d+:\d+', text, re.IGNORECASE))
def is_transcribed_by_otter(text):
    return bool(re.search(r'transcribed by https://otter\.ai', text, re.IGNORECASE))
	
def keep_between_ones(group):
    start_idx = group['firstrow'].idxmax()  # First occurrence of 1 in the second column
    end_idx = group['lastrow'].idxmax()    # First occurrence of 1 in the third column
    return group.loc[start_idx:end_idx-1]
	
# Define a function to classify the rows based on the 'line_str'
def classify_line_str(line):
    if re.match(r'Teacher.*\d{2}:\d{2}', line):
        return 1
    elif re.match(r'.*\d{2}:\d{2}', line):
        return 2
    else:
        return np.nan
		
# Define a function to extract the person (text before the timestamp) and timestamp
def extract_person_and_timestamp(line):
    # Use regex to match the format "[text] [timestamp]"
    match = re.search(r'(.+?)\s+(\d{2}:\d{2})', line)  # Adjusted to find any text before the timestamp
    if match:
        return match.group(1).strip(), match.group(2)
    else:
        return np.nan, np.nan
	
# Find Lines 
df_cleaned = df_cleaned.copy()
df_cleaned.loc[:, 'is_teacher_timestamp'] = df_cleaned['line_str'].apply(is_teacher_timestamp)
df_cleaned.loc[:, 'firstrow'] = df_cleaned.groupby('filename')['is_teacher_timestamp'].transform(lambda x: x.idxmax() == x.index).fillna(False).astype(int)
df_cleaned.loc[:, 'is_transcribed_by_otter'] = df_cleaned['line_str'].apply(is_transcribed_by_otter)
df_cleaned.loc[:, 'lastrow'] = df_cleaned['is_transcribed_by_otter'].apply(lambda x: 1 if x else 0)

# Keep between marked lines 
df_chopped = df_cleaned.groupby('filename', group_keys=False).apply(keep_between_ones)
df_chopped = df_chopped.drop(['firstrow', 'lastrow','is_teacher_timestamp','is_transcribed_by_otter'], axis=1)

# Classify Lines
df_chopped['classification'] = df_chopped['line_str'].apply(classify_line_str)

# Moving time stamp and speaker next to line instead of before
df_chopped['person'], df_chopped['timestamp'] = zip(*df_chopped.apply(lambda row: extract_person_and_timestamp(row['line_str']) if pd.notna(row['classification']) else (np.nan, np.nan), axis=1))
df_chopped['keep'] = df_chopped['classification'].apply(lambda x: 1 if pd.isna(x) else 0)
df_chopped['classification'] = df_chopped['classification'].ffill()
df_chopped['person'] = df_chopped['person'].ffill()
df_chopped['timestamp'] = df_chopped['timestamp'].ffill()

# Filter out lines that became new variable 
df_filtered = df_chopped[df_chopped['keep'] == 1]
df_filtered = df_filtered.drop(['keep'], axis=1)
df_filtered.reset_index(drop=True, inplace=True)

# Expand lines to sentences and then fill in other variables 
df_sentences = df_filtered.line_str.apply(lambda x: pd.Series(nltk.sent_tokenize(x))).stack().to_frame('sent_str')
df_sentences = df_sentences.reset_index(level=1, drop=True)
variables = ['filename', 'classification', 'person', 'timestamp','line_str']
for var in variables:
    df_sentences[var] = df_filtered[var].repeat(df_sentences.groupby(level=0).size()).values

# -----------------------------------------------------------------------------#
#  Tokenize Sentences
# -----------------------------------------------------------------------------#
keep_whitespace = True
if keep_whitespace:
    # Return a tokenized copy of text
    # using NLTK's recommended word tokenizer.
    df_tokens = df_sentences.sent_str.apply(lambda x: pd.Series(nltk.pos_tag(nltk.word_tokenize(x)))).stack().to_frame('pos_tuple')
else:
    # Tokenize a string on whitespace (space, tab, newline).
    # In general, users should use the string ``split()`` method instead.
    # Returns fewer tokens.
    df_tokens = SENTS.sent_str.apply(lambda x: pd.Series(nltk.pos_tag(nltk.WhitespaceTokenizer().tokenize(x)))).stack().to_frame('pos_tuple')
df_tokens['pos'] = df_tokens.pos_tuple.apply(lambda x: x[1])
df_tokens['token_str'] = df_tokens.pos_tuple.apply(lambda x: x[0])
df_tokens['term_str'] = df_tokens.token_str.str.lower().str.replace(r"\W+", "", regex=True)
df_tokens['pos_group'] = df_tokens.pos.str[:2]

variables = ['filename', 'classification', 'person', 'timestamp','sent_str','line_str']
repeat_counts = df_sentences['sent_str'].apply(lambda x: len(nltk.word_tokenize(x)))
for var in variables:
    df_tokens[var] = np.repeat(df_sentences[var].values, repeat_counts)
df_tokens = df_tokens[df_tokens.term_str != '']
df_tokens.head(50)
# -----------------------------------------------------------------------------#
#  Vocab Tables 
# -----------------------------------------------------------------------------#

df_tokens.head()

# Teacher Vocab 
df_tokens_teacher = df_tokens[df_tokens['classification'] == 1]
vocab_teacher = df_tokens_teacher['term_str'].value_counts().to_frame('n')
vocab_teacher.index.name = 'term_str'
vocab_teacher['p'] = vocab_teacher['n'] / vocab_teacher['n'].sum()  # Probability of each term
vocab_teacher['i'] = -np.log2(vocab_teacher['p'])  # Information content
vocab_teacher['n_chars'] = vocab_teacher.index.str.len()  # Number of characters in each term

#Student Vocab
df_tokens_student = df_tokens[df_tokens['classification'] == 2]
vocab_student = df_tokens_student['term_str'].value_counts().to_frame('n')
vocab_student.index.name = 'term_str'
vocab_student['p'] = vocab_student['n'] / vocab_student['n'].sum()  # Probability of each term
vocab_student['i'] = -np.log2(vocab_student['p'])  # Information content
vocab_student['n_chars'] = vocab_student.index.str.len()  # Number of characters in each term
vocab_student.head()

# -----------------------------------------------------------------------------#
#  Vocab Tables 
# -----------------------------------------------------------------------------#
end 


mkf data 
frame data {
	python: import sfi 
	python: df_tokens.sfi.Data.store()
}

import sys
from sfi import Data, Frame

# clone variables
def clone_var(f):
    nvar = Data.getVarCount()

    for i in range(nvar):
        varname = Data.getVarName(i)
        vartype = Data.getVarType(i)
        if vartype=="byte":
            f.addVarByte(varname)
        elif vartype=="double":
            f.addVarDouble(varname)
        elif vartype=="float":
            f.addVarFloat(varname)
        elif vartype=="int":
            f.addVarInt(varname)
        elif vartype=="long":
            f.addVarLong(varname)
        elif vartype=="strL":
            f.addVarStrL(varname)
        else:
            f.addVarStr(varname, 10)

        f.setVarFormat(i, Data.getVarFormat(i))
        f.setVarLabel(i, Data.getVarLabel(i))

# clone data values
def clone_data(f):
    f.setObsTotal(Data.getObsTotal())
    nvar = Data.getVarCount()

    for i in range(nvar):
        f.store(i, None, Data.get(var=i))

# create the new frame; the frame name is passed through
# the args() option of -python script-
newFrame = sys.argv[1]
fr = Frame.create(newFrame)

clone_var(fr)






















// python 

