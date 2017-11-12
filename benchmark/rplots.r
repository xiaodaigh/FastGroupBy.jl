library(data.table)
library(magrittr)
library(dplyr)

a = fread("C:/Users/dzj/.julia/v0.6/FastGroupBy/hehe5.csv")

library(ggplot2)

ggplot(a) + geom_bar(aes(x = as.factor(n), fill = factor(algo), weight = log(x1)), position = "dodge")


ggplot(a) + 
  geom_line(aes(x = log(n,2), color = factor(algo), y = log(x1)))

ggplot(a %>% filter(n > 2^16-1)) + 
  geom_line(aes(x = log(n,2), color = factor(algo), y = log(x1,10)))

ggplot(a %>% filter(n <= 2^16-1)) + 
  geom_line(aes(x = log(n,2), color = factor(algo), y = log(x1,10)))
