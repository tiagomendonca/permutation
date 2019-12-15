library(tidyverse)
library(rsample)


calculate <- function(data, group, value, statistic, boot = FALSE){
  
  results <- as.data.frame(data) %>% 
              group_by_at(group) %>% 
              summarise_each(match.fun(statistic), value) %>% 
              pivot_wider(names_from = group, values_from = value) %>% 
              mutate(dif = .[[1]] - .[[2]])
  
  if(boot) {
     return(select(results, dif)[[1]])
  } else {
     return(results)
  }
  
}



perm_test <- function(data, group, values, statistic, alternative = "two.sided", b = 2500){
  
  if(length(unique(data[[group]])) > 2) return("use only two groups")
  
  boot_s <- bootstraps(data, times = b) %>% 
             mutate(dif = map(splits, calculate, group, values, statistic))
  
  obs_dif <- calculate(data, group, values, statistic, boot = FALSE)
    
  data_dif <- tibble(diferencas = unlist(boot_s$dif))
  
  if(alternative == "less")      pval <- mean(    data_dif$diferencas  <     obs_dif$dif )
  if(alternative == "greater")   pval <- mean(    data_dif$diferencas  >     obs_dif$dif )
  if(alternative == "two.sided") pval <- mean(abs(data_dif$diferencas) > abs(obs_dif$dif))
  
  print(
  data_dif %>% 
    ggplot(aes(diferencas)) +
      geom_density(aes(color = "permutation difference"), size = 2, alpha = .4) + 
      geom_vline(xintercept = 0, col = "black", size = 1,linetype = "dashed") + 
      geom_vline(aes(xintercept = obs_dif$dif, color = "observed difference"), size = 2, linetype = "dashed") + 
      xlab("differences") +
      scale_color_manual(name = "", values = c("observed difference" = "red", "permutation difference" = "blue")) + 
      theme_bw() + theme(legend.position = "top"))
  
  return(mutate(obs_dif,
                statistic = pval))

}