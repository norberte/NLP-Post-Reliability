import re
from autocorrect import spell
from gensim import parsing

mentionFinder = re.compile(r"@[a-z0-9_]{1,15}", re.IGNORECASE)
html_tags = re.compile('<.*?>')
html_links = re.compile(r'^https?:\/\/.*[\r\n]*')

def __whiteSpaceAndNumericRemoval(text):
    cleanedText = parsing.preprocessing.strip_multiple_whitespaces(text)		# remove multiple white spaces
    #cleanedText = parsing.preprocessing.strip_numeric(cleanedText)  # remove numeric values
    #cleanedText = parsing.preprocessing.strip_tags(cleanedText)		# remove any kind of tags
    #cleanedText = parsing.preprocessing.strip_punctuation(cleanedText)

    # get rid of newlines
    #cleanedText = cleanedText.strip('\n')

    # replace twitter @mentions
    cleanedText = mentionFinder.sub('', cleanedText)

    # get rid of html tags
    #cleanedText = re.sub(html_tags, '', cleanedText)

    # get rid of html links
    cleanedText = re.sub(html_links, '', cleanedText)

    # replace HTML symbols
    cleanedText = cleanedText.replace("&amp;", "and").replace("&gt;", ">").replace("&lt;", "<")
    return cleanedText

# spell-checker
def __autoCorrect(s):
    return str(spell(s))

# adds spaces after each word went through pre-processing
def __spaces(s):
    return ' '.join(s.split())

# function that wraps all the pre-processing together
def preproc(s):
    #return __spaces(__whiteSpaceAndNumericRemoval(s.lower() ) )
    return __whiteSpaceAndNumericRemoval(s)


## From https://hpi.de//naumann/projects/web-science/comment-analysis/comment-classification.html
## Risch, J., & Krestel, R. (2018). Aggression identification using deep learning and data augmentation. In Proceedings of the First Workshop on Trolling, Aggression and Cyberbullying (TRAC-2018) (pp. 150-158).
## maybe we can use this

def str_normalize(s):
    """
    Given a text, cleans and normalizes it. Feel free to add your own stuff.
    """
    s = s.lower()
    s = re.sub(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}', ' _ip_ ', s)
    s = s.replace('...', ' dots ')
    s = s.replace('..', ' dots ')
    s = re.sub(r'([\'\"\.\(\)\!\?\-\\\/\,])', r' \1 ', s)
    s = re.sub(r'([\;\:\|\n])', ' ', s)
    s = s.replace('$', ' $ ')
    s = s.replace('&', ' and ')
    s = s.replace('0', ' zero ')
    s = s.replace('1', ' one ')
    s = s.replace('2', ' two ')
    s = s.replace('3', ' three ')
    s = s.replace('4', ' four ')
    s = s.replace('5', ' five ')
    s = s.replace('6', ' six ')
    s = s.replace('7', ' seven ')
    s = s.replace('8', ' eight ')
    s = s.replace('9', ' nine ')
    return s
