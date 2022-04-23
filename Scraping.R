library(RSelenium)
library(rvest)
library(stringr)
library(dplyr)

Main_link<-"https://www.whoscored.com/Regions/252/Tournaments/2/Seasons/8618/Stages/19793/Fixtures/England-Premier-League-2021-2022"


test<-read_html(Main_link)%>%
  html_text()

rD <- rsDriver(browser="firefox", port=4547L, verbose=F)
remDr <- rD[["client"]]

remDr$open() 

remDr$navigate(Main_link)




All_Links<-data.frame(link=as.character())

button<-remDr$findElement(using="xpath",'//*[@id="date-controller"]/a[1]')

prevpage<-"test"

i<-1
while (i==1){
  
  currentpage<-remDr$getPageSource()[[1]]
  
  if(currentpage==prevpage){
    break
  }
  
  links<-remDr$getPageSource()[[1]]%>%
    read_html()%>%
    html_nodes("a")%>%
    html_attr("href")
  
  links2<-links[str_detect(links,"MatchReport")]
  
  links3<-data.frame(link=links2)
  
  All_Links<-rbind(All_Links,links3)
  
  prevpage<-remDr$getPageSource()[[1]]
  
  button$clickElement()

  Sys.sleep(5)
  
  print(i)
  
}


All_Links<-All_Links[!duplicated(All_Links),]
All_Links<-data.frame(link=All_Links)

match_link<-paste("https://www.whoscored.com",All_Links[1,],sep="")

match_link<-gsub(match_link,pattern = "MatchReport",replacement = "LiveStatistics")

remDr$navigate(match_link)

date<-remDr$getPageSource()[[1]]%>%
  read_html()%>%
  html_nodes(xpath="//*[@id='match-header']/div/div[2]/span[3]/div[3]/dl/dd[2]")%>%
  html_text()
  

team1<-remDr$getPageSource()[[1]]%>%
  read_html()%>%
  html_nodes(xpath="//*[@id='match-header']/div/div[1]/span[2]/a")%>%
  html_text()

team2<-remDr$getPageSource()[[1]]%>%
  read_html()%>%
  html_nodes(xpath="//*[@id='match-header']/div/div[1]/span[6]/a")%>%
  html_text()

  
home<-remDr$getPageSource()[[1]]%>%
  read_html()%>%
  html_table()%>%
  .[[1]]%>%
  data.frame()%>%
  mutate(team="home",
         date=date,
         squad=team1,
         opp=team2)

away<-remDr$getPageSource()[[1]]%>%
  read_html()%>%
  html_table()%>%
  .[[2]]%>%
  data.frame()%>%
  mutate(team="away",
         date=date,
         squad=team2,
         opp=team1)

game_data<-rbind(home,away)

for(i in 2:nrow(All_Links)){
  match_link<-paste("https://www.whoscored.com",All_Links[i,],sep="")
  match_link<-gsub(match_link,pattern = "MatchReport",replacement = "LiveStatistics")
  
  remDr$navigate(match_link)
  
  Sys.sleep(sample(10:30,1))
  
  date<-remDr$getPageSource()[[1]]%>%
    read_html()%>%
    html_nodes(xpath="//*[@id='match-header']/div/div[2]/span[3]/div[3]/dl/dd[2]")%>%
    html_text()
  
  team1<-remDr$getPageSource()[[1]]%>%
    read_html()%>%
    html_nodes(xpath="//*[@id='match-header']/div/div[1]/span[2]/a")%>%
    html_text()
  
  team2<-remDr$getPageSource()[[1]]%>%
    read_html()%>%
    html_nodes(xpath="//*[@id='match-header']/div/div[1]/span[6]/a")%>%
    html_text()
  
  home<-remDr$getPageSource()[[1]]%>%
    read_html()%>%
    html_table()%>%
    .[[1]]%>%
    data.frame()%>%
    mutate(team="home",
           date=date,
           squad=team1,
           opp=team2)
  
  away<-remDr$getPageSource()[[1]]%>%
    read_html()%>%
    html_table()%>%
    .[[2]]%>%
    data.frame()%>%
    mutate(team="away",
           date=date,
           squad=team2,
           opp=team1)
  
  temp<-rbind(home,away)
  
  game_data<-rbind(game_data,temp)
  
print(i)
}

write.csv(game_data,"Original_Scrape.csv",row.names = F)

