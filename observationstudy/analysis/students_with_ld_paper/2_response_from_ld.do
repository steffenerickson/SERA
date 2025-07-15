
//----------------------------------------------------------------------------//
// Config
//----------------------------------------------------------------------------//
clear all 
frame reset 

	global root 	"/Users/steffenerickson"
	global code 	"Documents/GitHub/SERA/observationstudy"
	global data 	"Box Sync/ECR Observation Data/2023-2024 Final Data"
	global cleandata "Quant Team - Clean Data"
	global transcripts "transcripts"
	global programs "/Users/steffenerickson/Documents/GitHub/stata_programs"
	global output 	"Box Sync/ECR Observation Data/2023-2024 Final Data/Quant Team - Results" 

//----------------------------------------------------------------------------//
// Data and some cleaning 
//----------------------------------------------------------------------------//

use "${root}/${data}/${cleandata}/transcripts_byline.dta" , clear 

gen question = strpos(text ,"?") if teachertalk == 1

gen dummy = (question != 0) if teachertalk == 1

replace speaker = lower(speaker)
gen targettalk = strpos(speaker,"target")

tab studenttalk targettalk

replace text = regexr(text, "_+", "")
replace text = lower(text)


drop if regexm(text, "january|february|march|april|may|june|july|august|september|october|november|december") & targettalk == 1


gen wordcount = wordcount(text)
drop if wordcount == 0

sort id linenum 
by id : gen n = _n if targettalk == 1

browse if targettalk == 1

label define targetlbl 0 "Non-Target" 1 "Target"
label values targettalk targetlbl

regress wordcount targettalk i.id if studenttalk == 1
local diff = round(r(table)[1,1],.01)
local p = round(r(table)[4,1],.01)
graph box wordcount if studenttalk == 1 , ylabel(,nogrid) over(targettalk) nooutsides name(g1, replace) title("SWD OTR vs. Peer OTR Average Word Count" , size(small)) ///
note("Difference = `diff' words (pval = `p')")


gen before1 = 0 
gen before2 = 0 
replace before1 = 1  if studenttalk[_n+1] == 1
replace before2 = 1 if targettalk[_n+1] == 1 
replace before1 = 0 if teachertalk == 0 
replace before2 = 0 if teachertalk == 0 
label define targetbefore 0 "Non-Target" 1 "Target"
label values before2 targetbefore

regress wordcount before2  i.id if before1 == 1
local diff = round(r(table)[1,1],.01)
local p = round(r(table)[4,1],.01)
graph box wordcount if before1 == 1 , ylabel(,nogrid) over(before2)  box(1, color(red)) nooutsides name(g2, replace) title("Teacher Talk Word Count Before SWD OTR vs. Peer OTR" , size(small)) ///
note("Difference = `diff' words (pval = `p')")

gen after1 = 0 
gen after2 = 0 
replace after1 = 1  if studenttalk[_n-1] == 1
replace after2 = 1 if targettalk[_n-1] == 1 
replace after1 = 0 if teachertalk == 0 
replace after2 = 0 if teachertalk == 0 
label define targetafter 0 "Non-Target" 1 "Target"
label values after2 targetafter

regress wordcount after2 i.id if after1 == 1
local diff = round(r(table)[1,1],.01)
local p = round(r(table)[4,1],.01)
graph box wordcount if after1 == 1 ,  ylabel(,nogrid) over(after2)  box(1, color(green)) nooutsides name(g3, replace) title("Teacher Talk Word Count After SWDs OTR vs. Peers" , size(small)) ///
note("Difference = `diff' words (pval = `p')")

graph combine g1 g2 g3 , rows(1) altshrink title("Word Counts of SWD OTRs vs. Peer OTRs")


//----------------------------------------------------------------------------//
// Dictionaries 
//----------------------------------------------------------------------------//


include ${programs}/python_functions.ado 

//keep if studenttalk == 1 & targettalk == 0
//keep if studenttalk == 1 & targettalk == 0
//keep if before1 == 1 & before2 == 1
keep if before1 == 1 & before2 == 1
keep linenum id text

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
df = df.set_index(['id','linenum'])

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

OHCO = ['id','linenum','sentnum','tokennum']
sent = OHCO[:3]
lines = OHCO[:2]
transcript = OHCO[:1]
vocab_filter = 'dfidf'
n_terms = 300
pos_list = "NN NNS VB VBD VBG VBN VBP VBZ JJ JJR JJS RB RBR RBS".split() # Open categories with no proper nouns
#pos_list = "NN NNS VB VBD VBG VBN VBP VBZ".split() # Open categories with no proper nouns
#pos_list = "VB VBD VBG VBN VBP VBZ".split() 
pos_list = "NN NNS".split() 
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
bow_lines = create_bow(corpus, bag=transcript,item_type='term_str')
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
vocabtosave = vocab.dfidf.sort_values(ascending=False).head(300) 
end 


//python : vocabtosave.to_csv('${root}/${data}/${cleandata}/vocab_target.csv', index=True)
//python : vocabtosave.to_csv('${root}/${data}/${cleandata}/vocab_nontarget.csv', index=True)
//python : vocabtosave.to_csv('${root}/${data}/${cleandata}/vocab_beforetarget.csv', index=True)
python : vocabtosave.to_csv('${root}/${data}/${cleandata}/vocab_before_nontarget.csv', index=True)





clear 
frame reset 
mkf fr1
mkf fr2
mkf fr3
mkf fr4
frame fr1: import delimited using "${root}/${data}/${cleandata}/vocab_target.csv" , clear
frame fr2: import delimited using "${root}/${data}/${cleandata}/vocab_nontarget.csv" , clear 
frame fr3: import delimited using "${root}/${data}/${cleandata}/vocab_beforetarget.csv" , clear
frame fr4: import delimited using "${root}/${data}/${cleandata}/vocab_before_nontarget.csv" , clear 

frame copy fr1 all, replace 
frame all {
	gen vocab = 1
	forvalues i = 2/4 {
		frame fr`i' : gen vocab = `i'
		frame fr`i' : tempfile data
		frame fr`i' : save `data'
		append using `data'
	}
}

frame change all 

gsort + vocab - dfidf
by vocab: gen n = _n

label define types 1 "SWD" 2 "Peer" 3 "Teacher before SWD" 4 "Teacher before Peer"
label values vocab types 
label variable n "Rank"

tabdisp n vocab , cellvar(term_str) 

drop dfidf
reshape wide term_str, i(n) j(vocab)

label variable n "Frequency Rank"
label variable term_str1 "SWD OTR"
label variable term_str2 "Peer OTR"
label variable term_str3 "Teacher Talk Before SWD OTR"
label variable term_str4 "Teacher Talk Before Peer OTR"
export excel using "${root}/${data}/${cleandata}/vocab_table_all.xlsx" , firstrow(varlabels)




