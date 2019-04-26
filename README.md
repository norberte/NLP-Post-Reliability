# NLP-Post-Reliability


## Introduction
  Stack Overflow (SO) is the most popular question answering website for software developers, providing a large amount of code snippets and free-form texton a wide variety of topics. In the latest public data dump from December 9th 2018 SO listed over 42 million posts from almost 10 million registered users. Similar to other software artifacts such as source code files and doc-umentation, text and code snippets on SO evolve over time. An example ofthis is when the SO community fixes bugs in code snippets, clarifies questionsand answers, and updates documentation to match new API versions. Toanalyze how SO posts evolve Baltes et al. [2] built SOTorrent [1], an opendata set aggregating and connecting the official SO data dump to other websources, such as GitHub repositories. SOTorrent provides access to versionhistories of SO content at two separate levels: whole posts and individualtext or code blocks. Since the existence of SO in 2008, a total of 13.9 million SO posts havebeen edited after their creation.  19,708 of these posts have been edited even more than ten times.  300 million Software developers and engineers visit Stack Overflow monthly [3]. This number show the scale of interaction
happening at this platform. When a questions is asked or answered, mostof discussion and interaction related to that topic happens in the form of comments. Comments can be associated with a question or an answer. These comments provide rich source of natural language text (mainly in English) tostudy developers’ attitude towards a topic. As part of this research projectwe aim to explore this database to answer some research questions.

## Motivation
At the Mining Software Repositories (MSR) conference in 2018, SOTorrent, a database built on entire SO content was released. In the submission paper[1] the authors performed top level analysis on this database. As part of [1],Baltes et al. claimed that out of all posts on SO, 38.6% have been edited after their creation. Furthermore, the authors of the paper argued that alledited posts are very rich in comments. They have large number of comments compared to non-edited posts. They inferred that these comments lead tothe edit of the post. As part of this project we would like to perform very specific sentimental analysis on these text rich comments of edited post to argue about nature of these comments. In particular we are hoping to catchdiscontent or doubt in form of comment on SO post in question. We believe if exact sentiment of comment is identified, one can argue about reliability of information of presented in form of SO post.

## References
[1] Baltes, S., Dumani, L., Treude, C., and Diehl, S.Sotorrent: reconstructing and analyzing the evolution of stack overflow posts. InProceedings of the 15th International Conference on Mining SoftwareRepositories, MSR 2018, Gothenburg, Sweden, May 28-29, 2018(2018),pp. 319–330.

[2] Baltes, S., Treude, C., and Diehl, S.Sotorrent: Studying the ori-gin, evolution, and usage of stack overflow code snippets.arXiv preprintarXiv:1809.02814(2018).

[3] StackExchange. Stack exchange traffic statistics, 2018
