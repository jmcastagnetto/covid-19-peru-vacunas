library(arrow)
dataset <- open_dataset("tmp/arrow_augmented_data")
write_dataset(
  dataset,
  partition = c("dosis"),
  path = "tmp/arrow_augmented_by_dose_data"
)
