import pandas as pd
import text_cleaning
import datetime

csv_filepath = "../../data/EditHistoryofPosts.csv"
json_filepath = "../../data/clean_EditHistory_Of_Posts.json"

def csv2pandasDF(filepath):
    df = pd.read_csv(filepath, encoding="ISO-8859-1", header=0, names=["Id", "PostHistoryTypeId", "PostId", "RevisionGUID", "Edit_TimeStamp", "UserId", "Edit_Comment"])
    return df

def main():
    data = csv2pandasDF(csv_filepath)

    # text cleaning
    print("started preprocessing ...")
    data['clean_editComment'] = data['Edit_Comment'].apply(text_cleaning.preproc)
    print("finished preprocessing ...")

    # convert string date to datetime object
    data['Edit_Date'] = data["Edit_TimeStamp"].apply(lambda x: datetime.datetime.strptime(str(x), "%Y-%m-%dT%H:%M:%S"))

    data.sort_values(by=['PostId', 'Edit_Date'], ascending=[True, True])

    #print(data.head(30))

    data.to_json(json_filepath, orient='table')


if __name__ == '__main__':
    main()
