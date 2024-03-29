test_that("Reading names from the web works", {
  expect_true(any(grepl("Moran", extract_people(con="https://web.archive.org/web/20200819142546/http://www.nasonline.org/member-directory/living-member-list.html"))))
})

test_that("Reading names from text works", {
  expect_true(any(grepl("Moran", extract_people(text="A key person working on symbiosis is Nancy Moran."))))
})

test_that("Pulling data from ASMD works", {
	known <- get_misconduct(agree=TRUE)
	expect_gte(nrow(known), 900)
	expect_true(inherits(known, "data.frame"))
})

test_that("True matches work", {
	asmd <- get_misconduct(agree=TRUE)
	nasem <- extract_people(con="https://web.archive.org/web/20200819142546/http://www.nasonline.org/member-directory/living-member-list.html")
	apparent_matches <- match_misconduct(nasem, asmd)
	expect_true(any(grepl("Marcy", apparent_matches$Pool)))
})