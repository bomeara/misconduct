# misconduct

Package to check names against a misconduct database to flag for manual inspection.

To use, you will need to install openNLPmodels.en from http://datacube.wu.ac.at/, in addition to the other required packages from CRAN: `install.packages("openNLPmodels.en", repos = "http://datacube.wu.ac.at/", type = "source")`

My motivation in developing this package is to help scientific societies identify bad actors who have harmed others in their organization and use a fair process, involving human judgment, to decide about possible ways to protect their members (banning individuals from attending conferences, for example) -- the package can be used for other things, many moral, but also some immoral. It is a potentially powerful tool, so use it humanely.

This downloads information (currently just from the [Academic Sexual Misconduct Database](https://academic-sexual-misconduct-database.org) (Libarkin 2020) for users who agree to terms) to match against names extracted from other documents. This is to allow easy flagging of possible matches. For example, some members of the National Academy of Sciences have been found guilty of substantial misconduct, but [they have received no complaints about them, even though there is now a complaint system](https://www.nature.com/articles/d41586-020-02640-7). It can be difficult to manually compare the over a thousand academics in the misconduct database with the hundreds of people in the National Academy of Sciences, and this tool can be a first step to make this comparison easier. However, there are some important caveats for its use. Name matches are uncertain: many people will have the same name, so even a perfect match might not be the same individual. **Even with a perfect first and last name match, a human needs to check to see if the people are the same.** There is also the opposite issue: some true matches might be missed ("Patricia Smith" in one document might not match "Patty Smith" in another). One can change the leniency to address the latter problem, though this will result in many more false matches. The defaults allow "Geoffrey" to match "Geoff" but also for "Janet" to match "James". There also needs to be one or more humans involved in deciding how to act on any true matches -- for example, it may be illegal to exclude any true matches from a pool of job candidates. It is important to consider the impact of using information from past convictions: see information on the "[ban the box](https://en.wikipedia.org/wiki/Ban_the_Box)" movement, for example. In the target use case for this package, of finding typically senior scientists who have been disciplined for gross misconduct so that professional societies can choose to, for example, ban such scientists from judging student talk competitions, there still needs to be a just process to make sure the misconduct warrants the sanctions. However, this technology could be abused, too -- for example, by excluding people from a job pool based on a database of arrests. 

Besides the database of names, it requires one or more names to match to. If you have a vector of names, perhaps loaded from a spreadsheet, it can use this directly, but if not, the `extract_people()` function can use natural language processing to get potential names from a file you have locally or from a web page even in the midst of other text.

## Legal

This package has no data itself; instead, it downloads data from the [Academic Sexual Misconduct Database](https://academic-sexual-misconduct-database.org), though it is written in such a way that other databases can be added in the future. An important thing to note is the license under which the data are released: "This database includes evidenced cases of academic sexual misconduct and cases where relationship policies were violated. All cases are based on publicly available documents or media reports, and only cases documented publicly can be included." The full legal information is at https://academic-sexual-misconduct-database.org/legal. You must read this **before** using the dataset.

Anyone using the Academic Sexual Misconduct Database (for example, by using the `misconduct` R package) should reference it as written below. Since the database is continually updated, the retrieval date is particularly important:

Libarkin, J. (2020). Academic Sexual Misconduct Database. Retrieved MONTH/DAY/YEAR, from https://academic-sexual-misconduct-database.org


## Usage


```
devtools::install_github("bomeara/misconduct")
library(misconduct)
nasem <- extract_people(con="http://www.nasonline.org/member-directory/living-member-list.html")
asmd <- get_misconduct(agree=TRUE)
apparent_matches <- match_misconduct(nasem, asmd)
print(apparent_matches[,c("Pool", "Person", "FirstNameMismatchFraction")])
```

You will note in this example that some of the matches are not correct: first names can be very different and still have a match, but increasing stringency then misses people who go by a shortened version of their name in one of the databases. There may also be people who should match but who don't. This just shows the difficulties in name matching and the need for humans in the process. However, this does help compare hundreds of names in a pool of, say, meeting attendees with a pool of over a thousand people who are in a misconduct database to flag potential issues ahead of time.