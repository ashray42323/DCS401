import os
os.environ["NLTK_ALLOW_PROXIED_URLOPEN"] = "1"
import nltk
from nltk import word_tokenize, sent_tokenize
from nltk.probability import FreqDist
from nltk.corpus import stopwords
from wordcloud import WordCloud
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

text = '''Natural language processing lets computers read and understand human language.
Text messaging, product reviews, and emails are examples of text data.
NLP turns this messy text into something a computer can actually analyze.'''

# split into sentences and words
sentences = sent_tokenize(text)
words = word_tokenize(text)
print("Number of sentences:", len(sentences))
print("Number of word tokens:", len(words))
print("\nFirst 12 tokens:", words[:12])

# most common tokens before cleaning
fdist = FreqDist(words)
print("\nMost common (raw):", fdist.most_common(6))

# remove punctuation and lowercase
words_nopunc = [w.lower() for w in words if w.isalpha()]

# remove stopwords
stop = stopwords.words("english")
words_clean = [w for w in words_nopunc if w not in stop]
print("\nMost common (cleaned):", FreqDist(words_clean).most_common(6))
print("Tokens left after cleaning:", len(words_clean))

# word cloud of the cleaned words
wc = WordCloud(width=800, height=400, background_color="white").generate(" ".join(words_clean))
plt.figure(figsize=(10, 5))
plt.imshow(wc)
plt.axis("off")
plt.tight_layout()
plt.savefig("figures/wordcloud.png", dpi=150)
plt.close()
print("\nword cloud saved to figures/wordcloud.png")
