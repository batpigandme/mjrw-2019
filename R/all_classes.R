mjrw_2019_all_classes <- read_csv(here::here("data", "raw", "mjrw_2019_all_classes.csv"))

mjrw_2019_all_classes %>%
  select(1:`Boat Name/Club`) %>%
  colnames() -> specialcols

mjrw_all_classes <- mjrw_2019_all_classes %>%
  rowid_to_column() %>%
  fill(`Sail Number`, .direction = "up") %>%
  fill(-one_of(specialcols), .direction = "down") %>%
  dplyr::group_by(`Sail Number`) %>%
  dplyr::mutate(sailor_count = dplyr::row_number()) %>%
  ungroup()

have_boats <- mjrw_all_classes %>%
  filter(sailor_count == 2) %>%
  drop_na(`Boat Name/Club`)

no_boats <- mjrw_all_classes %>%
  filter(sailor_count == 2) %>%
  anti_join(have_boats) %>% # get the ones we didn't drop
  select(-`Boat Name/Club`) # get rid of this column bc all NA

have_boats_clubs <- mjrw_all_classes %>%
  filter(sailor_count == 2) %>%
  drop_na(`Boat Name/Club`) %>%
  rename(Club = `Boat Name/Club`)

no_boats_clubs <- mjrw_all_classes %>%
  filter(`Sail Number` %in% no_boats$`Sail Number`,
         sailor_count == 1) %>%
  rename(Club = `Boat Name/Club`)




sails_clubs <- have_boats_clubs %>%
  bind_rows(no_boats_clubs) %>%
  select(`Sail Number`, Club)

sails_names <- mjrw_all_classes %>%
  filter(`Sail Number` %in% have_boats$`Sail Number`,
         sailor_count == 1) %>%
  rename(`Boat Name` = `Boat Name/Club`) %>%
  select(`Sail Number`, `Boat Name`)

info_by_sails <- sails_clubs %>%
  left_join(sails_names)

clubs <- read_csv(here::here("data", "clean", "clubs.csv"))

clean_mjrw_all_classes <- mjrw_all_classes %>%
  left_join(info_by_sails) %>%
  select(-`Boat Name/Club`) %>%
  rename(Sailor = `Sailor(s)`) %>%
  drop_na(Sailor) %>%
  left_join(clubs, by = c("Club" = "club_raw")) %>%
  rename(`Club Name` = club_norm) %>%
  select(`Sail Number`, Sailor, `Boat Name`, `Club Name`)

write_csv(clean_mjrw_all_classes, here::here("data", "clean", "all_classes.csv"))
          