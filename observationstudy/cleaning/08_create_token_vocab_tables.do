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


mkf base 
frame change base 
use "${root}/${data}/${cleandata}/transcripts_byline.dta" , clear 
include ${programs}/python_functions.ado 

keep if teachertalk == 1
gen textlen = wordcount(text)
keep if textlen > 19
keep linenum id text
sort id linenum 

bysort id: gen line = _n
gen subgroup = ceil(line / 4)
drop line 

tab subgroup 



//----------------------------------------------------------------------------//
// Code to create token and vocab tables 
//----------------------------------------------------------------------------//


qui ds 
local varlist `r(varlist)'
python 
# --------------------- 
# Packages  
# --------------------- 
import numpy as np 
import re
import nltk
import pandas as pd
from nltk.tokenize import sent_tokenize
from sfi import Data,Frame, Macro

# --------------------- 
# import stata data 
# --------------------- 

df =  pd.DataFrame(Data.get('`varlist''))
df.columns = Macro.getLocal('varlist').split()
df = df.set_index(['id','subgroup','linenum'])

# --------------------- 
# Expand to sentences 
# --------------------- 
df_sentences = split_by_sentence(df,'text')

# --------------------- 
# Tokenize Setences 
# ---------------------
df_tokens = tokenize_sentences(df_sentences,'text')
df_tokens = df_tokens[df_tokens.term_str != '']
df_tokens = df_tokens[df_tokens['term_str'].str.isalpha()]

# --------------------- 
# Extract Vocab 
# ---------------------
vocab = df_tokens.term_str.value_counts().to_frame('n')
vocab.index.name = 'term_str'
vocab['p'] = vocab.n / vocab.n.sum()
vocab['i'] = -np.log2(vocab.p)
vocab['n_chars'] = vocab.index.str.len()

# --------------------- 
# Max POS
# --------------------- 
df_tokens[['term_str','pos_group']].value_counts().sort_index().loc['love']
df_tokens[['term_str','pos']].value_counts().sort_index().loc['love']
vocab['max_pos_group'] = df_tokens[['term_str','pos_group']].value_counts().unstack(fill_value=0).idxmax(1)
vocab['max_pos'] = df_tokens[['term_str','pos']].value_counts().unstack(fill_value=0).idxmax(1)

# --------------------- 
# POS ambiguity
# --------------------- 
vocab['n_pos_group'] = df_tokens[['term_str','pos_group']].value_counts().unstack().count(1)
vocab['cat_pos_group'] = df_tokens[['term_str','pos_group']].value_counts().to_frame('n').reset_index()\
    .groupby('term_str').pos_group.apply(lambda x: set(x))
vocab['n_pos'] = df_tokens[['term_str','pos']].value_counts().unstack().count(1)
vocab['cat_pos'] = df_tokens[['term_str','pos']].value_counts().to_frame('n').reset_index()\
    .groupby('term_str').pos.apply(lambda x: set(x))
vocab.sort_values('n_pos')

# --------------------- 
# Remove Stop Words 
# --------------------- 
sw = pd.DataFrame({'stop': 1}, index=nltk.corpus.stopwords.words('english'))
sw.index.name='term_str'

if 'stop' not in vocab.columns:
    vocab = vocab.join(sw)
    vocab['stop'] = vocab['stop'].fillna(0).astype('int')

# --------------------- 
# Add Word stems 
# --------------------- 
from nltk.stem.porter import PorterStemmer
stemmer = PorterStemmer()
vocab['porter_stem'] = vocab.apply(lambda x: stemmer.stem(x.name), 1)
df_tokens['porter_stem'] = df_tokens['token_str'].apply(stemmer.stem)

end 


//----------------------------------------------------------------------------//
// TFIDF For PCA 
//----------------------------------------------------------------------------//

python

OHCO = ['id','subgroup','linenum','sentnum','tokennum']
sent = OHCO[:4]
lines = OHCO[:3]
linegroup = OHCO[:2]
transcript = OHCO[:1]
vocab_filter = 'dfidf'
n_terms = 1000
pos_list = "NN NNS VB VBD VBG VBN VBP VBZ JJ JJR JJS RB RBR RBS".split() # Open categories with no proper nouns
#pos_list = "NN NNS VB VBD VBG VBN VBP VBZ".split() # Open categories with no proper nouns
#pos_list = "VB VBD VBG VBN VBP VBZ".split() 
#pos_list = "NN NNS".split() 
#pos_list = "VB VBD VBG VBN VBP VBZ".split() 
corpus = df_tokens.set_index(OHCO)
corpus.columns
# Additonal filters
corpus = corpus[corpus['pos_group'].isin(pos_list)]
corpus = corpus[corpus['term_str'].str.len() > 2]
vocab .columns
vocab = vocab.reset_index()
vocab = vocab[vocab['max_pos_group'].isin(pos_list)]
vocab = vocab[vocab['term_str'].str.len() > 1]
vocab = vocab.set_index('term_str')
end 
python: vocab.head()

python:

# bag of words at the line level 
bow_lines = create_bow(corpus, bag=lines,item_type='term_str')
dtcm_lines = bow_lines.n.unstack(fill_value=0)

# TFIDF Method 
tfidf_lines, dfidf_lines = get_tfidf(bow_lines, tf_method='max', df_method='standard',item_type='term_str')

# Add DFIDF to vocab table
vocab['dfidf'] = dfidf_lines
vocab['mean_tfidf'] = tfidf_lines.mean()

# Add TFIDF to BOW table
bow_lines['tfidf'] = tfidf_lines.stack()
bow_lines
vocab.dfidf.sort_values(ascending=False).head(50) 
vocabtosave = vocab.dfidf.sort_values(ascending=False).head(500) 
end 

python 
VIDX = vocab.loc[vocab.max_pos.isin(pos_list)]\
    .sort_values(vocab_filter, ascending=False)\
    .head(n_terms).index

#M = tfidf_lines[VIDX].fillna(0).groupby(['id']).mean() # MUST FILLNA
M = tfidf_lines[VIDX].fillna(0).groupby(['id','subgroup','linenum']).mean() # MUST FILLNA
end 

python : M.to_csv('${root}/${data}/${cleandata}/TFIDF.csv', index=True)
python : vocabtosave.to_csv('${root}/${data}/${cleandata}/vocab.csv', index=True)















