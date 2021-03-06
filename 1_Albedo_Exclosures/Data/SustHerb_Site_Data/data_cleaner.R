#This script cleans up the original dataset from Snøan 2019 (located in 'original_data')
#and stores it in 'cleaned_data'


#Import original CSV into data frame
data <- read.csv('1_Albedo_Exclosures/1_Data/Sites/original_data/snøan_site_data.csv', header = TRUE)


#DATA CLEANING
        #Clean site names (to lowercase and replace spaces w/ underscores)
        data$LocalityName <- tolower( sub(' ', '_', data$LocalityName) )
        
        #Clean region names (to lowercase)
        data$Region <- tolower( data$Region )
        
        #Clean treatment names (either 'open' or 'exclosure')
        data$Treatment <- tolower( sub(' plot', '', data$Treatment) )

#WRITE TO CSV
        write.csv(data, '1_Albedo_Exclosures/1_Data/Sites/cleaned_data/cleaned_data.csv', row.names = TRUE)
        