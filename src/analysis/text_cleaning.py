import re
from gensim import parsing

mentionFinder = re.compile(r"@[a-z0-9_]{1,15}", re.IGNORECASE)
links = re.compile(r'''(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?]))''')
html_links = re.compile(r'^https?:\/\/.*[\r\n]*')

def __whiteSpaceAndNumericRemoval(text):
    cleanedText = parsing.preprocessing.strip_multiple_whitespaces(text)		# remove multiple white spaces
    #cleanedText = parsing.preprocessing.strip_numeric(cleanedText)  # remove numeric values
    #cleanedText = parsing.preprocessing.strip_tags(cleanedText)		# remove any kind of tags
    #cleanedText = parsing.preprocessing.strip_punctuation(cleanedText)

    # replace twitter @mentions
    cleanedText = mentionFinder.sub('', cleanedText)

    # get rid of html links
    cleanedText = re.sub(links, '', cleanedText)
    cleanedText = re.sub(html_links, '', cleanedText)

    # replace HTML symbols and weird code-tag
    cleanedText = cleanedText.replace("?&#xD;&#xA;&#xD;&#xA;&#xD;&#xA;", "")
    return cleanedText

# function that wraps all the pre-processing together
def preproc(s):
    return __whiteSpaceAndNumericRemoval(s)

