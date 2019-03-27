import pandas as pd
import text_cleaning
import datetime

csv_filepath = "../../data/CommentsFiltered.csv"
json_filepath = "../../data/CleanComments.json"

def csv2pandasDF(filepath):
    df = pd.read_csv(filepath, encoding="ISO-8859-1", header=0, names=["Id", "PostId", "Score", "Text", "CreationDate", "UserId", "IdAgain"])
    return df

def main():
    data = csv2pandasDF(csv_filepath)

    # text cleaning
    print("starting preprocessing ...")
    data['clean_text'] = data['Text'].apply(text_cleaning.preproc)
    print("finished preprocessing ...")

    # convert string date to datetime object
    data['Date'] = data['CreationDate'].astype('string')
    data['Date'] = data['Date'].apply(lambda x: x[:-4])

    data['Date'] = data['Date'].apply(lambda x: datetime.datetime.strptime(str(x), "%Y-%m-%dT%H:%M:%S"))

    data.sort_values(by=['Id', 'Date'], ascending=[True, True])

    print(data.head(30))

    data.to_json(json_filepath, orient='table')


if __name__ == '__main__':
    main()
