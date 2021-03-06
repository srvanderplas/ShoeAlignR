context("ellipse")

testthat::setup({
  `%>%` <- dplyr::`%>%`

  if (!file.exists("poo.rds")) {
    poopath <- "https://upload.wikimedia.org/wikipedia/commons/thumb/9/92/Emojione_1F4A9.svg/240px-Emojione_1F4A9.svg.png"
    temp_poo <- tempfile(fileext = ".png")
    download.file(poopath, destfile = temp_poo, quiet = T)
    poo <- suppressMessages(imager::load.image(temp_poo)) %>%
      imager::rm.alpha() %>%
      imager::bucketfill(x = 1, y = 1, color = c(1,1,1), sigma = 0)

    saveRDS(poo, "poo.rds")
  }
})

testthat::teardown({
  if (file.exists("poo.rds")) {
    file.remove("poo.rds")
  }
  if (file.exists("test0.png")) {
    file.remove("test0.png")
  }
  if (file.exists("test1.png")) {
    file.remove("test1.png")
  }
})

# --- Setup for contour_ellipse_fit --------------------------------------------
img <- readRDS("poo.rds") %>% imager::grayscale()
img_tc <- img %>%
  outer_contour %>%
  thin_contour(img = img, n_angles = 12)
img_tc_df <- img %>%
  outer_contour %>%
  thin_contour(img = img, n_angles = 12, as_cimg = F)
img_tc_mat <- as.matrix(img_tc_df[,1:2])
# ------------------------------------------------------------------------------

test_that("contour_ellipse_fit works as expected", {
  ellipsefit <- contour_ellipse_fit(img_tc)
  ellipsefitdf <- contour_ellipse_fit(img_tc_df)
  ellipsefitmat <- contour_ellipse_fit(img_tc_mat)
  ellipsefitchull <- contour_ellipse_fit(img_tc, chull = T)

  expect_equal(names(ellipsefit),
               c("CenterX", "CenterY", "AxisA", "AxisB", "Angle"))
  expect_equal(names(ellipsefitchull),
               c("CenterX", "CenterY", "AxisA", "AxisB", "Angle"))
  expect_equivalent(ellipsefit, ellipsefitdf)
  expect_equivalent(ellipsefit, ellipsefitmat)
})

# --- Setup for ellipse_points -------------------------------------------------
edf <- data.frame(CenterX = 0, CenterY = 0, AxisA = 10, AxisB = 5, Angle = 0)
tmp <- ellipse_points(edf, n = 50, plot_lines = F)
png("test0.png")
plot(x = 0, y = 0, type = "p", xlim = c(-15, 15), ylim = c(-15, 15))
dev.off()

png("test1.png")
plot(x = 0, y = 0, type = "p", xlim = c(-15, 15), ylim = c(-15, 15))
tmp <- ellipse_points(edf, n = 50, plot_lines = T)
dev.off()
# ------------------------------------------------------------------------------

test_that("ellipse_points works as expected", {
  expect_lte(max(tmp$y), 5)
  expect_gte(max(tmp$y), -5)
  expect_lte(max(tmp$x), 10)
  expect_gte(max(tmp$x), -10)
  expect_length(tmp$x, 50)
  expect_false(
    visualTest::isSimilar(
      file = "test1.png",
      fingerprint = visualTest::getFingerprint(file = "test0.png"),
      threshold = 0.1)
  )
})

