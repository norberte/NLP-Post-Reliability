import os
import csv

class Post:
    def __init__(self, postId):
        self.postId = postId
        self.number_of_comments = []
        self.total_score_between_edits = []
        self.commulative_score = []
        self.sentiment_vector = []
        self.tags = []
        self.acceptance_time = None

    def test(self):
        assert len(self.total_score_between_edits) == len(self.commulative_score), \
            "Scores are not same length for postId {0}".format(self.postId)
        sum = 0
        for i in range(len(self.total_score_between_edits)):
            sum += self.total_score_between_edits[i]
            assert sum == self.commulative_score[i], "There is error on score for postId {0}".format(self.postId)
            break


def recover_an_array(line, idx):
    if isinstance(line, list):
        ret = []
        if "[" in line[idx]:
            val = float(line[idx].replace("\"[", ''))
            ret.append(val)
        idx += 1
        word = line[idx]
        while "]" not in word:
            val = float(word)
            ret.append(val)
            idx += 1
            word = line[idx]
        if "]" in line[idx]:
            val = float(line[idx].replace("]\"", ''))
            ret.append(val)
            idx += 1
        return ret, idx
    else:
        print("ERROR : Format is not consistent")

def create_a_post(line):
    if line:
        words = line.split(',')
        id = int(words[0])
        print(id)
        over_all_score = float(words[1])
        print(over_all_score)
        sentiment_vector, idx = recover_an_array(words, 2)
        number_of_comments, idx = recover_an_array(words, idx)
        total_score_between_edits, idx = recover_an_array(words, idx)
        commulative_score_between_edits, idx = recover_an_array(words, idx)
        aPost = Post(id)
        aPost.commulative_score = commulative_score_between_edits
        aPost.number_of_comments = number_of_comments
        aPost.total_score_between_edits = total_score_between_edits
        aPost.sentiment_vector = sentiment_vector
        return aPost
    return None


directory = "../R_directory/sentiment tag trend results"

for filename in os.listdir(directory):
    file_name = os.path.join(directory, filename)

    file = open(file_name, 'r')
    lines = file.readlines()

    posts = list()

    for a_line in lines:
        try:
            post_obj = create_a_post(a_line)
        except ValueError:
            post_obj = None
            continue
        if post_obj:
            posts.append(post_obj)


    print("Number of Posts recovered {0}".format(len(posts)))


    cum_positve_score_of_posts = []
    cum_negative_score_of_posts = []
    maximum_number_of_edits = 0
    for a_post in posts:
        if len(a_post.commulative_score) > maximum_number_of_edits:
            maximum_number_of_edits = len(a_post.commulative_score)
    print("Maximum number of edits of a post is ",maximum_number_of_edits)

    for i in range(0, maximum_number_of_edits):
        positive_count = 0
        negative_count = 0
        for a_post in posts:
            if i < len(a_post.commulative_score):
                if a_post.commulative_score[i] >= 0:
                    positive_count += 1
                else:
                    negative_count += 1
        cum_positve_score_of_posts.append(positive_count)
        cum_negative_score_of_posts.append(negative_count)
        print("Positve posts are {0} and negative are {1}".format(positive_count, negative_count))



    with open(filename + 'Analysis.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',
                                quotechar='|', quoting=csv.QUOTE_MINIMAL)
        row = []
        for i in range(0, maximum_number_of_edits):
            row.append(i+1)
            row.append(cum_positve_score_of_posts[i])
            row.append(cum_negative_score_of_posts[i])
            spamwriter.writerow(row)
            row = []
    positive_score_post_edit = list()
    negative_score_post_edit = list()


    for i in range(0, maximum_number_of_edits):
        positive_count = 0
        negative_count = 0
        for a_post in posts:
            if i < len(a_post.total_score_between_edits):
                if a_post.total_score_between_edits[i] >= 0:
                    positive_count += 1
                else:
                    negative_count += 1
        positive_score_post_edit.append(positive_count)
        negative_score_post_edit.append(negative_count)
        print("Positve posts are {0} and negative are {1}".format(positive_count, negative_count))

    with open(filename + 'AnalysisOnlyEditPointOfView.csv', 'w', newline='') as csvfile:
        spamwriter = csv.writer(csvfile, delimiter=',',
                                quotechar='|', quoting=csv.QUOTE_MINIMAL)
        row = []
        for i in range(0, maximum_number_of_edits):
            row.append(i+1)
            row.append(positive_score_post_edit[i])
            row.append(negative_score_post_edit[i])
            spamwriter.writerow(row)
            row = []

