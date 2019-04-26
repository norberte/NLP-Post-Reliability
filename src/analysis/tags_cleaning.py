import pandas as pd
import datetime

csv_filepath = "../../data/PostTags.csv"
json_filepath = "../../data/clean_posts_tags.json"

def csv2pandasDF(filepath):
    df = pd.read_csv(filepath, encoding="ISO-8859-1", header=0, names=["PostId", "ParentId", "Score", "OwnerUserId",
                                                                       "LastEditorUserId", "LastEditorDisplayName",
                                                                       "LastEditDate", "LastActivityDate",
                                                                       "Tags","CommentCount"])
    return df

def main():
    data = csv2pandasDF(csv_filepath)

    # convert string date to datetime object
    data['Edit_Date'] = data["Edit_TimeStamp"].apply(lambda x: datetime.datetime.strptime(str(x), "%Y-%m-%dT%H:%M:%S"))

    data.sort_values(by=['PostId', 'Edit_Date'], ascending=[True, True])

    #print(data.head(30))

    data.to_json(json_filepath, orient='table')


if __name__ == '__main__':
    main()
