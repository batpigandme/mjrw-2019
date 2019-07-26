---
author: Mara Averick
date: '2019-07-26'
title: Cleaning up Junior Race Week
output:
  html_document:
    keep_md: true
---



I [came across](https://twitter.com/dataandme/status/1154532351235547138) the list of registrants for the 2019 Marblehead Junior Race Week (MJRW) in the local paper, and was kind of appalled by the lack of data cleaning. Indignant outrage without action is cheap, so I thought I'd give it a go myself.

After a few attempts using [rvest](https://rvest.tidyverse.org/index.html), I discovered that the data is, indeed, in a super nasty format (aren't `iframes` fun, kids?), and had to go to copy-pasta-ing. But, aside from that (as well the removal of annoying 🇺🇸 flags, and addition of a `Class` variable), the data is still pretty gross. In fact, I'm keeping the window with the [results online](https://www.regattatoolbox.com/results?eventID=8tDOrn7dbe) open as I go to help me parse the madness.

## Packages


```r
library(tidyverse)
library(here)
```


## Import and inspect

Because each class (420 Champ, 420 Green, Laser, Opti Champ, and Opti Green) has its own structure (i.e. the column headers are not the same), I'll deal with them one by one.


```r
mjrw_2019_420_champ <- read_csv(here::here("data", "raw", "mjrw_2019_420_champ.csv"), 
    col_types = cols(Position = col_integer()))

mjrw_2019_420_champ
```

```
## # A tibble: 76 x 12
##    Class Position `Sail Number` `Sailor(s)` `Boat Name/Club` Points R1   
##    <chr>    <int> <chr>         <chr>       <chr>             <dbl> <chr>
##  1 420 …        1 <NA>          Brooks Reed Hingham Yacht C…      8 1    
##  2 420 …       NA USA 871       Trent Hess… <NA>                 NA <NA> 
##  3 420 …        2 <NA>          Sawyer Reed Hingham Yacht C…     20 2    
##  4 420 …       NA USA 8241      Andrew Eng… <NA>                 NA <NA> 
##  5 420 …        3 <NA>          James Know… Buck's Harbor Y…     21 5    
##  6 420 …       NA USA 1905      Sloan Phil… <NA>                 NA <NA> 
##  7 420 …        4 <NA>          Ian McCaff… Kiss My Transom      22 3    
##  8 420 …       NA USA 2296      Katy Benagh Sandy Bay Yacht…     NA <NA> 
##  9 420 …        5 <NA>          Sandy Yale  Portland Yacht …     28 8    
## 10 420 …       NA USA 6906      Elsa Dean-… <NA>                 NA <NA> 
## # … with 66 more rows, and 5 more variables: R2 <chr>, R3 <chr>, R4 <chr>,
## #   R5 <chr>, R6 <chr>
```

So, WTF is going on here? Let's look at [the source](https://www.regattatoolbox.com/results?eventID=8tDOrn7dbe) and see:

![420 Champ results](https://i.imgur.com/2xzehTg.png)

The first difference you probably see is that we've got an abundance of `NA`s, while the original table does not (mainly because there's a bunch of annoying _merged cell_ stuff going on behind the scenes). Each boat (identified by `Sail Number`) has multiple `Sailor(s)`, and the data seems to get oddly divvied up between the two: the `Position` value shows up with the first sailor's name, while the `Sail Number` is down in the row below with the latter. There's also the matter of the decidedly _untidy_ `Boat Name/Club` variable, which contains more than one piece of information.

I'm going to subset the data frame by `Sailor(s)` for illustration purposes, below.[^1]


```r
select_sailors <- c("Brooks Reed", "Trent Hesselman", "Ian McCaffrey", "Katy Benagh")

mjrw_2019_420_champ %>%
  filter(`Sailor(s)` %in% select_sailors)
```

```
## # A tibble: 4 x 12
##   Class Position `Sail Number` `Sailor(s)` `Boat Name/Club` Points R1   
##   <chr>    <int> <chr>         <chr>       <chr>             <dbl> <chr>
## 1 420 …        1 <NA>          Brooks Reed Hingham Yacht C…      8 1    
## 2 420 …       NA USA 871       Trent Hess… <NA>                 NA <NA> 
## 3 420 …        4 <NA>          Ian McCaff… Kiss My Transom      22 3    
## 4 420 …       NA USA 2296      Katy Benagh Sandy Bay Yacht…     NA <NA> 
## # … with 5 more variables: R2 <chr>, R3 <chr>, R4 <chr>, R5 <chr>,
## #   R6 <chr>
```


### Data modelling

Now's a good moment to pause and think about how we want our data to look in the end. We _could_ turn `Sailor(s)` into a list column, but I'd rather give each sailor their own row. We also need to separate boat and club names into their own columns, e.g. `Boat Name` and `Club`.

The pair that came in first didn't have their own boat, which can make things look misleadingly simple:

![420 Champ - Position 1](https://i.imgur.com/NpbzX8L.gif)

For the pair that came in fourth, you wouldn't be able to use this same strategy until _after_ `Boat Name/Club` has been separated into two columns:

![420 Champ - Position 4](https://i.imgur.com/isae1Zv.gif)

[^1]: Yes, it turns out there _are_ actually two records that have `NA` for `Sailor(s)`, which is weird, bc I'm pretty sure this was a two-handed race.
