suppressPackageStartupMessages(library(tidyverse))

mjrw_2019_opti_green <- read_csv(here::here("data", "raw", "mjrw_2019_opti_green.csv"), 
                                col_types = cols(Position = col_integer()))

mjrw_2019_opti_green %>%
  select(1:`Boat Name/Club`) %>%
  colnames() -> specialcols



mjrw_opti_green <- mjrw_2019_opti_green %>%
  rowid_to_column() %>%
  fill(`Sail Number`, .direction = "up") %>%
  fill(Position, .direction = "down") %>%
  fill(-one_of(specialcols), .direction = "down") %>%
  dplyr::group_by(`Sail Number`) %>%
  dplyr::mutate(sailor_count = dplyr::row_number()) %>%
  ungroup()



have_boats <- mjrw_opti_green %>%
  filter(sailor_count == 2) %>%
  drop_na(`Boat Name/Club`)

no_boats <- mjrw_opti_green %>%
  filter(sailor_count == 2) %>%
  anti_join(have_boats) %>% # get the ones we didn't drop
  select(-`Boat Name/Club`) # get rid of this column bc all NA

have_boats_clubs <- mjrw_opti_green %>%
  filter(sailor_count == 2) %>%
  drop_na(`Boat Name/Club`) %>%
  rename(Club = `Boat Name/Club`)

no_boats_clubs <- mjrw_opti_green %>%
  filter(Position %in% no_boats$Position,
         sailor_count == 1) %>%
  rename(Club = `Boat Name/Club`)




sails_clubs <- have_boats_clubs %>%
  bind_rows(no_boats_clubs) %>%
  select(Position, `Sail Number`, Club) %>%
  arrange(Position)

sails_names <- mjrw_opti_green %>%
  filter(Position %in% have_boats$Position,
         sailor_count == 1) %>%
  rename(`Boat Name` = `Boat Name/Club`) %>%
  select(Position, `Sail Number`, `Boat Name`)

info_by_sails <- sails_clubs %>%
  left_join(sails_names)

clean_mjrw_opti_green <- mjrw_opti_green %>%
  left_join(info_by_sails) %>%
  select(-`Boat Name/Club`) %>%
  rename(Sailor = `Sailor(s)`) %>%
  select(1:Sailor, `Boat Name`, Club, everything()) %>%
  drop_na(Sailor)


# add club-name correction
clubs <- read_csv(here::here("data", "clean", "clubs.csv"))

all_classes <- read_csv(here::here("data", "clean", "all_classes.csv"))

clean_mjrw_opti_green <- clean_mjrw_opti_green %>%
  left_join(all_classes) %>%
  select(-Club) %>%
  select(-sailor_count) %>%
  select(rowid, Class, Position, `Sail Number`, Sailor, `Boat Name`, `Club Name`, everything())

write_csv(clean_mjrw_opti_green, here::here("data", "clean", "opti_green.csv"))
