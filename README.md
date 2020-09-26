# misconduct

Package to check names against a misconduct database to flag for manual inspection

Download information (currently just from the [Academic Sexual Misconduct Database](https://academic-sexual-misconduct-database.org) (Libarkin 2020)) to match against names extracted from other documents. This is to allow easy flagging of possible matches (for example, which current members of the National Academy of Sciences have been found guilty of misconduct). However, there are some important caveats for its use. Name matches are uncertain: many people will have the same name, so even a perfect match might not be the same individual. There is also the opposite issue: some true matches might be missed ("Patricia Smith" in one document might not match "Patty Smith" in another). One can change the leniency to address the latter problem, though this will result in many more false matches. The defaults allow "Geoffrey" to match "Geoff" but also for "Janet" to match "James". There also needs to be one or more humans involved in deciding how to act on any true matches -- for example, it may be illegal to exclude any true matches from a pool of job candidates. It is also worth considering the impact on past convictions: see information on the "[ban the box](https://en.wikipedia.org/wiki/Ban_the_Box)" movement, for example. 

My motivation in developing this package is to help scientific societies identify bad actors who have harmed others in their organization and use a fair process, involving human judgment, to decide about possible ways to protect their members (banning individuals from attending conferences, for example) -- the package can be used for other things, many moral, but also some immoral. It is a potentially powerful tool, so use it humanely.

Besides the database of names, it requires one or more names to match to -- for example, a list of current National Academy of Sciences members. If you have a vector of names in R it can use this directly, but if not, the `extract_people()` function can use natural language processing to get potential names from a file you have locally or from a web page.

This package has no data itself; instead, it downloads data from the [Academic Sexual Misconduct Database](https://academic-sexual-misconduct-database.org), though it is written in such a way that other databases can be used in the future. An important thing to note is the license under which the data are released: "This database includes evidenced cases of academic sexual misconduct and cases where relationship policies were violated. All cases are based on publicly available documents or media reports, and only cases documented publicly can be included." The full legal information is at https://academic-sexual-misconduct-database.org/legal. You must read this **before** using the dataset.

Anyone using the Academic Sexual Misconduct Database should reference it as written below. Since the database is continually updated, the retrieval date is particularly important:

Libarkin, J. (2020). Academic Sexual Misconduct Database. Retrieved MONTH/DAY/YEAR, from https://academic-sexual-misconduct-database.org


To use:

```
devtools::install_github("bomeara/misconduct")
library(misconduct)
nasem <- extract_people(con="http://www.nasonline.org/member-directory/living-member-list.html")
asmd <- get_misconduct(agree=TRUE)
apparent_matches <- match_misconduct(nasem, asmd)
print(apparent_matches[,c("Pool", "Person", "FirstNameMismatchFraction", "Specific Outcome")])
```

You will note in this example that some of the matches are not correct: first names can be very different and still have a match, but increasing stringency then misses people who go by a shortened version of their name in one of the databases. There may also be people who should match but who don't. This just shows the difficulties in name matching and the need for humans in the process. However, this does help compare hundreds of names in a pool of, say, meeting attendees with a pool of thousands of people who are in a misconduct database to flag potential issues ahead of time.