####################
####################
##1-1 Data Transform
####################
####################

rm(list = ls())
gc()
options(stringsAsFactors = FALSE)
setwd("JobMining")

##����=>²��
##type: �u�@���� or ���[����
##"total = T" => ����
##"total = F" => ����~
OutputSimplify <- function(type, total = F){
  FNamePlus<- ifelse(total, "\\����", "")
  ##Read mutiple csv files to one DF
  csv_list <- list.files(paste0(".\\����~�Ooutput\\", type, FNamePlus), pattern="*�������G.csv")
  #myfiles <- lapply(temp, read.delim)
  for(i in 1:length(csv_list)){
    temp <- read.csv(csv_list[i], stringsAsFactors=F)
    temp <- temp[, 2]
    temp <- unique(temp)
    temp <- temp[!is.na(temp)]
    temp <- cbind(substr(csv_list[i], 1, unlist(gregexpr(pattern = " -", csv_list[i]))[1]-1), substr(csv_list[i], unlist(gregexpr(pattern = "- ", csv_list[i]))[1]+2, unlist(gregexpr(pattern = type, csv_list[i]))[1]-1), temp)
    colnames(temp) <- c("¾�ȦW��", "��~�O", type)
    temp <- temp[order(temp[, 3]), ]
    write.csv(temp, paste0(".\\����~�Ooutput\\", type, FNamePlus, "²��\\", gsub("����", "²��", csv_list[i])), row.names=F)
    cat("\r", type, ifelse(total, "������~", "����~"), i/length(csv_list)*100, " %", rep(" ", 50))
  }
  cat("\n")
}

##Job discriptions with industry
OutputSimplify("�u�@����", total=F)
##Job discriptions without industry
OutputSimplify("�u�@����", total=T)

##Export total form
CombinationExport <- function(type){
  csv_list <- list.files(paste0(".\\����~�Ooutput\\", type, "\\²��"), pattern="*²�Ƶ��G.csv")
  csv_list <- c(csv_list, list.files(paste0(".\\����~�Ooutput\\", type, "\\����\\²��"), pattern="*²�Ƶ��G.csv"))
  myfiles <- {}
  for(i in 1:length(csv_list)){
    tryCatch({
      temp    <- read.csv(csv_list[i], stringsAsFactors=F)
      myfiles <- rbind(myfiles, temp)
      cat("\r", type, "��X�ɮ� ", i/length(csv_list)*100, "%", rep(" ", 50))
    }, error = function(e) {
      print(paste0(csv_list[i], "���~"))
    })
  }
  myfiles <- unique(myfiles)
  write.csv(myfiles, paste0(".\\����~�Ooutput\\", type, "�`��.csv"), row.names=F)
}

##Job Discriptions with and without industry
CombinationExport("�u�@����")

####################
####################
##2-1 Data Cleaning
####################
####################

if(T){
  ##Returns string without leading or trailing whitespace
  trim <- function (x) gsub("^\\s+|\\s+$", "", x)
  ##Something like trim, but will remove punctuations except quotation marks : () �]�^
  trim_punc <- function (x){
    #gsub("^[[:punct:]]+|[[:punct:]]+$", "", x)
    gsub("([()�]�^])|^[[:punct:]]+|[[:punct:]]+$", "\\1", x)
  }
  
  job_d <- read.csv(".\\����~�Ooutput\\�u�@�����`��.csv")
  
  ##Leading minus sign will cause problem in Excel.
  ##job_d$�u�@���� <- gsub("-","*",job_d$�u�@����)
  job_d$�u�@���� <- trim_punc(job_d$�u�@����)
  job_d$�u�@���� <- trim(job_d$�u�@����)
  job_d$�u�@���� <- gsub(",", "�A", job_d$�u�@����)
  
  if(F){
    ##Comparing strings.
    ##If both of it just make difference in one char, remove one of the string...
    uni_job_list <- unique(job_d[,c("¾�ȦW��","��~�O")])
    
    for(i in 1:nrow(uni_job_list)){
      split_tmp <- strsplit(job_d$�u�@����[which(job_d$¾�ȦW��==uni_job_list$¾�ȦW��[i] & job_d$��~�O==uni_job_list$��~�O[i])], "")  
    }
  }
  
  write.csv(job_d, ".\\����~�Ooutput\\�u�@�����B�z���`��.csv", row.names=F)
  
  ##Fuzzy matching
  job_d_list <- job_d[,1:2]
  job_d_list <- unique(job_d_list)
  
  for(i in 1:nrow(job_d_list)){
    tmp            <- job_d[which(job_d[,1]==job_d_list[i,1] & job_d[,2]==job_d_list[i,2]), ]
    wordlist       <- expand.grid(words = tmp[,3], ref = tmp[,3], stringsAsFactors = FALSE)
    fuzzy_matching <- wordlist %>% mutate(match_score = jarowinkler(words, ref))
    
    ##Why using tostring and as numeric? 
    ##Because sometimes the comparing is wronge
    fuzzy_matching <- fuzzy_matching[which(fuzzy_matching$match_score >=0.9 & fuzzy_matching$match_score < 1), ]
    ##Maybe 0.9 is to high...
    fuzzy_matching <- fuzzy_matching[which(fuzzy_matching[,1]!=fuzzy_matching[,2]), ]
    ##fuzzy_matching[order(fuzzy_matching$match_score),]
    if(nrow(fuzzy_matching)>0){
      #apply(fuzzy_matching, 1, function(x) print(paste0(x[1]," <==> ",x[2])))
      
      #export_df = rbind(export_df,fuzzy_matching)
      #sink("D:\\abc\\wjhong\\projects\\�t�Ӫ�¾�Ȥj�`��\\jobwiki\\����~�Ooutput\\����u�@����fuzzymatch����.txt",append=TRUE)                      
      #apply(fuzzy_matching, 1, function(x) print(paste0(x[1]," <==> ",x[2])))
      #sink()
      
      get_min_nchar <- apply(fuzzy_matching, 1, function(x){
        if(nchar(x[1]) > nchar(x[2])){
          return(x[2])
        }else{
          return(x[1])
        }
      })
      get_min_nchar <- unique(as.vector(get_min_nchar))
      job_d         <- setdiff(job_d,tmp[which(get_min_nchar %in% tmp$�u�@����), ])
      #tmp[which(get_min_nchar %in% job_d$�u�@����),]
      #job_d = job_d[which(job_d[,1]==job_d_list[i,1] & job_d[,2]==job_d_list[i,2] & !get_min_nchar %in% job_d$�u�@����),]
    }
    print(paste0(i/nrow(job_d_list)*100, "%"))
  }
  
  ##write.csv(export_df,"D:\\abc\\wjhong\\projects\\�t�Ӫ�¾�Ȥj�`��\\jobwiki\\����~�Ooutput\\����u�@����fuzzymatch����.csv",row.names=F)
  nrow(job_d)
  job_d$�u�@���� <- gsub("[*]","-", job_d$�u�@����)
  write.csv(job_d, ".\\����~�Ooutput\\����u�@����fuzzymatch���z���G.csv",row.names=F)
}

####################
####################
##2-2 Data Cleaning
####################
####################

if(T){
  library(RecordLinkage)
  library(dplyr)
  library(jiebaR)
  cutter = worker()
  
  ##Custom trim function
  trim <- function (x){
    gsub("^[�@�܄P�֡N�_//s]+|[�@�܄P�_�N//s]+$", "",gsub("^\\s+|\\s+$", "", x))
  } 
  ##triming star symbols
  trim_star <- function (x) gsub("^[*]+|[*]+$", "", x)
  ##Trimming punctuations except quotation marks : () �]�^
  trim_punc <- function (x){
    #gsub("^[[:punct:]]+|[[:punct:]]+$", "", x)
    gsub("([()�]�^])|^[[:punct:]]+|[[:punct:]]+$", "\\1", x)
  }
  ##Custom trim with mixed factors
  trim_mix <- function(x){
    x <- gsub("^\\)+|\\(+$", "", x)
    ##Sometimes have to trim multiple times...
    x <- gsub("��", " ", x)
    x <- gsub("^[0-9��-��a-zA-Z�@-�Q�|��]{1,2}[:�B�N�A,�E �D)�^-��]", "", x)
    x <- gsub("^[0-9��-��a-zA-Z�@-�Q�|��]{1,2}[.]", "", x)
    x <-  gsub("^[0-9��-��a-zA-Z�@-�Q�|��]{1,2}-", "", x)
    ##New discovery!! Numbers used by Chinese is functional.
    ##But the word "�|" has failed.
    x <- gsub("^[(�]][0-9��-��a-zA-Z�@-�Q�|��]{1,2}[)�^]", "", x)
    x <- gsub("^��", "", x)
    
    if(grepl("^[(�]��]+", x) & grepl("[)�^��]+$", x)){
      x <- gsub("^[(�]��]+|[)�^��]+$", "", x)
    }
    x <- gsub("^[0-9��-��]{1,2}[-][0-9��-��]{1,2}", "", x)
    
    if(grepl("\\)", x) & grepl("\\(", x) & length(unlist(gregexpr("\\)", x)))==1 & length(unlist(gregexpr("\\(", x)))==1){
      if(unlist(gregexpr("\\)", x)) < unlist(gregexpr("\\(", x))){
        x <- "" ##It will be removed at the final stage...
      }
    }
    if(grepl("[0-9][0-9]:[0-9][0-9]", x)){
      x <- ""
    }
    ##Remove Date
    if(grepl("[0-9][/][0-9]", x)){
      x <- ""
    }
    ##�n but no �m, or �m but no �n
    if(grepl("�m", x) & !grepl("�n", x)){
      x <- unlist(strsplit(x, "�m"))[1]
    }else if(!grepl("�m", x) & grepl("�n", x)){
      x <- unlist(strsplit(x, "�n"))[length(unlist(strsplit(x, "�n")))]
    }else{
      ##
    }
    # Their's problem
    #if(length(nchar(unlist(lapply(strsplit(x,","),trim)))[which(nchar(unlist(lapply(strsplit(x,","),trim)))==1)])>0){
    #  x = unlist(lapply(strsplit(x,","),trim))[which(nchar(unlist(lapply(strsplit(x,","),trim)))==max(nchar(unlist(lapply(strsplit(x,","),trim)))))][1]
    #}
    return(x)
  }
  trim_du <- function(x){
    ##Removed when occur multiple times?
    #if(length(unlist(gregexpr(pattern ="[0-9��-��a-zA-Z�@-�Q�|��]+[:�B�A,-�E �D)�^.]",x)))>1 | length(unlist(gregexpr(pattern ="[0-9��-��a-zA-Z]+[.]",x)))>1){
    ##if(grepl("[0-9��-��a-zA-Z�@-�Q�|��]+[:�B�A,-�E �D)�^.��]",x)){
    if(grepl("[0-9��-��a-zA-Z�@-�Q�|��]{1,2}[:�E�D��]", x) | grepl("[0-9��-��a-zA-Z�@-�Q�|��]{1,2}-", x) | grepl("[0-9��-��a-zA-Z�@-�Q�|��]{1,2}[.]", x)){
      x <- ""
    }else{
      #x <- x
    }
    return(x)
  }
  ##Using jiebaR to remove words?
  remove_head_num_jiebar <- function(x){
    if(grepl("^[0-9]", x)){
      if(substr(x,2,2) %in% c("�~", "�U", "��", "�y", "��", "�p")){
      }else if(substr(x,2,2) %in% c("��")){
        x <- gsub("^[0-9]", "", x)
      }else{
        tmp = cutter <= x
        if(nchar(tmp[2]) != 1){
          x <- gsub("^[0-9]", "", x)
        }
      }
    }
    return(x)
  }
  
  ##What file!?
  ##I forgot...
  ##The code below is to remove useless discription
  ##Therefore the file should be discriptionMining()"s output or so.
  #job_d  <- read.csv(file.choose())
  job_d <- read.csv(".\\����~�Ooutput\\����u�@����fuzzymatch���z���G.csv", stringsAsFactors=F)
  
  job_d <- job_d[which(!grepl("[0-9]+$", job_d[,3])), ]
  #toMatch= c("�f��", "²��", "�x��", "�x�_", "�x�F", "�x�n",  "�y��",  "�F�F",  "�Ὤ",	"����",	"�n��",	"�n�F",	"�̪F",	"�]��",	"���",	"�Q��",	"����",	"����",	"��",	"���L",	"�s��",	"�Ÿq",	"����",	"���",	"�O��",	"�O�_",	"�O�F",	"�O�n", "���B", "�Ÿ�", "����", "�p�j", "�H", "?", "$", "�u��", "���W�ɶ�", "www", "@", "com", "���զa�I", "�N��", "�t��", "���u", "�W�Z��", "�s���q��", "�p���覡", "���~", "�O��", "�Хߩ�", "1111", "asp", "��", "�����۶�", "���~", "�ڭ̤��q",	"���",	"�ݹJ��",	"���~",	"��~�ɶ�",	"�ӹq",	"���V�����~��",	"���ծɶ�",	"�������q",	"�z�K",	"�ۼx", "�p��", "�u�@�ݹJ", "���~", "�u�@�ɬq", "�ȥ�", "���~", "�u�@�a��", "�u�@�a�I", "�ɬq", "�w��", "�i��", "�u�@���e", "�����q", "�ثe", "�A�n", "�j�a�n", "�u�@�ɶ�", "����", "�a�}", "�W�Z�ɶ�", "�Ǯɶ}�l", "�p�O�覡")
  #for(i in 1:length(toMatch)){
  #  job_d <- job_d[which(!grepl(toMatch[i], job_d[,3],fixed=T)), ]
  #}
  
  ##Remove discriptions with Date or Time.
  ##job_d <- job_d[which(!grepl("[0-9��-��]{4}",job_d[,3])), ]
  #job_d <- job_d[which(!grepl("[0-9]�I[0-9]", job_d[, 3])), ]
  #job_d <- job_d[which(!grepl("[��-��]�I[��-��]",job_d[, 3])), ]
  #job_d <- job_d[which(!grepl("[0-9��-��]�G[0-9��-��]", job_d[, 3])), ]
  #job_d <- job_d[which(!grepl("[��-��]�G[��-��]", job_d[, 3])), ]
  #job_d <- job_d[which(!grepl("[0-9��-��]:[0-9��-��]", job_d[, 3])), ]
  #job_d <- job_d[which(!grepl("^[0-9��-��]{3}", job_d[, 3])), ]
  #job_d <- job_d[which(!grepl("[0-9��-��]{2}�~", job_d[, 3])), ]
  
  job_d <- job_d[which(!(grepl("[0-9��-��]{5,}",job_d[,3]) & grepl("[a-zA-Z]",job_d[,3]))), ]
  
  toMatch = c("�ɤs", "�H�q", "�N��", "����", "�Z",	"�p��",	"��",	"��",	"��",	"���",	"�g",	"�_",	"~",	"-",	"line",	"�q", "��", "�~")
  for(i in 1:length(toMatch)){
    if(grepl("[a-z]", tolower(toMatch[i]))){
      job_d <- job_d[which(!(grepl("[0-9��-��]{3,}", job_d[,3]) & !grepl("0800",job_d[,3]) & grepl(tolower(toMatch[i]), tolower(job_d[,3]), fixed=T))), ]
    }else{
      job_d <- job_d[which(!(grepl("[0-9��-��]{3,}", job_d[,3]) & !grepl("0800",job_d[,3]) & grepl(toMatch[i], job_d[,3], fixed=T))), ]
    }
  }
  job_d <- job_d[which(!(grepl("[0-9��-��]{3,}", job_d[,3]) & !grepl("0800", job_d[,3]) & !grepl("[a-zA-Z]", job_d[,3]))), ]
  job_d <- job_d[which(!(grepl("[0-9��-��]{3,}", job_d[,3]) & grepl("�Z", job_d[,3]))), ]
  
  #tmp = job_d[which(grepl("[(�]]",job_d[,3]) & !grepl("[)�^]",job_d[,3])),3]
  job_d[which(grepl("[(�]]", job_d[,3]) & !grepl("[)�^]", job_d[,3])),3] <- 
    unlist(lapply(job_d[which(grepl("[(�]]", job_d[,3]) & !grepl("[)�^]", job_d[,3])), 3],function(x){
      x <- trim(substr(x, 1, unlist(gregexpr(pattern ="[(�]]",x))[length(unlist(gregexpr(pattern ="[(�]]",x)))] - 1))
      if(nchar(x)<=4){
        x=""
      }
      return(x)
    }))
  
  ##Fuzzy matching
  ##Job and Industry...
  job_d_list <- job_d[,1:2]
  job_d_list <- unique(job_d_list)
  
  ##Empty DF
  new_job_df = job_d[0, ]
  
  if(T){
    for(times in 1:2){
      job_d[, 3] <- trim(job_d[, 3])
      job_d[, 3] <- trim_star(job_d[, 3])
      job_d[, 3] <- trim_punc(job_d[, 3])
      job_d[, 3] <- trim_mix(job_d[, 3])
      #for(i in 1:nrow(job_d)){
      #  job_d[i, 3] <- trim_du(job_d[i, 3])
      #}
      job_d[, 3] <- unlist(lapply(job_d[, 3], trim_du))
    }
    
    ##This block of code is for "Other needs"
    #job_d <- job_d[which(!grepl(".com",job_d[, 3],fixed=T) & !grepl("�q��",job_d[, 3]) & !grepl("�ӹq",job_d[, 3]) & !grepl("font",job_d[, 3]) & !grepl("�q��",job_d[, 3]) & !grepl("e-mail",job_d[, 3]) & !grepl("�i",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("�j",job_d[, 3])), ]
    job_d <- job_d[which(!grepl(".com",job_d[, 3],fixed=T) & !grepl("font",job_d[, 3]) & !grepl("�i",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("��",job_d[, 3]) & !grepl("�j",job_d[, 3])), ]
    
    job_d <- job_d[which(job_d[, 3]!=""), ]
    
    #job_d <- job_d[which(!grepl("^[(�]��?�H]+",job_d[, 3])), ]
    #job_d <- job_d[which(!grepl("[?�H]+",job_d[, 3])), ]
    job_d <- job_d[which(nchar(job_d[, 3]) > 4), ]
    
    job_d[, 3] <- unlist(lapply(job_d[, 3],remove_head_num_jiebar))
    
    #job_d <- job_d[which(!grepl("^[(�]]",job_d[, 3])), ]
    #job_d <- job_d[which(!grepl("^��",job_d[, 3])), ]
    #job_d <- job_d[which(!grepl("^��",job_d[, 3])), ]
    
    job_d[, 3] <- gsub("�@"," ",job_d[, 3])
    job_d[, 3] <- gsub("[~]+","�A",job_d[, 3])
    job_d[, 3] <- gsub("��","�B",job_d[, 3])
    
    job_d[which(grepl("�p�ɪA�ȭ�",job_d[, 3])), 3] <- "�p�ɪA�ȭ�"
  }
  
  ##job_d_list
  ##Job and Industry...
  x = 1
  for(i in 1:nrow(job_d_list)){
    tmp <- job_d[which(job_d[,1]==job_d_list[i,1] & job_d[,2]==job_d_list[i,2]), ]
    if(nrow(tmp)<6){
      job_d <- job_d[which(!(job_d[,1]==job_d_list[i,1] & job_d[,2]==job_d_list[i,2])), ]
    }else{
      ##Remove similar discriptions...
      wordlist       <- expand.grid(words = tmp[,3], ref = tmp[,3], stringsAsFactors = FALSE)
      fuzzy_matching <- wordlist %>% mutate(match_score = jarowinkler(words, ref))
      fuzzy_matching <- fuzzy_matching[order(fuzzy_matching$match_score), ]
      fuzzy_matching <- fuzzy_matching[which(fuzzy_matching[,3]<0.9999), ]
      #fuzzy_matching[,1]  
      #fuzzy_matching[,2]
      #ord_v = unique(trim(unlist(strsplit(paste(fuzzy_matching[,1],"�C", fuzzy_matching[,2]),"�C"))))
      
      ##Max score side as the head side...
      #unique(rev(fuzzy_matching[seq(1, nrow(fuzzy_matching), 2),1]))
      ord_v <- unique(rev(fuzzy_matching[,1]))
      
      temp = c()
      for(j in 1:length(unique(substr(ord_v,1,5)))){
        temp = c(temp, ord_v[which(unique(substr(ord_v,1,5))[j]==substr(ord_v,1,5))][1])
      }
      
      ord_v <- temp[1:20]
      ord_v <- sort(ord_v)
      ord_v <- ord_v[!is.na(ord_v)]
      
      ord_v_rm = c()
      for(check_i in 1:length(ord_v)){
        ##Extract "grepl=True" but different with the original one?
        if(length(which(grepl(ord_v[check_i],ord_v,fixed=TRUE)))==1){
          ord_v_rm <- c(ord_v_rm, ord_v[check_i])
        }
      }
      ord_v <- ord_v_rm
      
      new_job_df[x:(x+length(ord_v)-1), 1:2] <- tmp[1:(length(ord_v)), 1:2]
      new_job_df[x:(x+length(ord_v)-1), 3]   <- ord_v
      
      cat(paste0("\r", format(round(i/nrow(job_d_list)*100,3),nsmall=3), "%"))
      x <- x + length(ord_v)
    }
  }
  
  #write.csv(new_job_df,".\\����~�Ooutput\\[edit�z���4]����u�@����fuzzymatch���z���G.csv",row.names=F)
  write.csv(new_job_df,".\\����~�Ooutput\\�z���_�u�@�����`��.csv",row.names=F)
}