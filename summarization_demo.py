import os
os.environ["NLTK_ALLOW_PROXIED_URLOPEN"] = "1"
from sumy.parsers.plaintext import PlaintextParser
from sumy.nlp.tokenizers import Tokenizer
from sumy.summarizers.lsa import LsaSummarizer
from sumy.summarizers.luhn import LuhnSummarizer
from sumy.summarizers.lex_rank import LexRankSummarizer

text = """Big data refers to datasets that are too large or complex for traditional software to handle.
A lot of this data is text, such as customer reviews, emails, and social media posts.
Text is unstructured, so it does not fit neatly into rows and columns like a spreadsheet.
Natural language processing helps computers read and make sense of this text.
Common steps include tokenization, which splits text into words and sentences.
Stopword removal deletes very common words that carry little meaning.
Sentiment analysis then decides whether a piece of text is positive or negative.
Text summarization shortens a long document into a few key sentences.
This saves time when there are thousands of documents to read.
Companies use these techniques to turn raw text into useful business decisions."""

n = 3  # number of sentences in each summary
parser = PlaintextParser.from_string(text, Tokenizer("english"))

print("=== LexRank Summary ===")
for s in LexRankSummarizer()(parser.document, n):
    print("-", s)

print("\n=== Luhn Summary ===")
for s in LuhnSummarizer()(parser.document, n):
    print("-", s)

print("\n=== LSA Summary ===")
for s in LsaSummarizer()(parser.document, n):
    print("-", s)
