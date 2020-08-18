### Another COVID-19 tracker ###

There are many webs tracking data from COVID-19. Som simple, some really difficult to use.

This site has 3 parts:

    - Galeria Infame is a simple graphic of the 10 countries with more declared vodie deaths by 1000000 people. Be careful not all countries declare exactly equal.
    
    - Països shos the evolution of COVID in different countries with more than 500.000 inhabitants. Tracks cases, deaths and excess deaths as computed accordint to NYT. It includes, of course, Catalunya as a country.
    
        You may set axis as linea or logarithmic, select cases or deaths, apply a simple filter ans compute cases/million people, very useful for checking Luxembourg agints USA for example.
    
    - Comarques : There are the territorial distributions of Catalonia. As some are quite small one must be aware of the meaning of the data.
    
Data sources are :

    - For countries data is from [ECDC](https://www.ecdc.europa.eu/en/publications-data/download-todays-data-geographic-distribution-covid-19-cases-worldwide)
    
    - For Catalonia and Comarques data is from [transparència catalunya - Registre de casos COVID-19 realitzats a Catalunya.](https://dev.socrata.com/foundry/analisi.transparenciacatalunya.cat/jj6z-iyrp)
    
        Data does not include deaths but it categorizes cases into Positive by PCR, Positive by Fast test and ELISA and just suspect cases. More explanation is in the link for the dataset.
    
    
    - For excess deaths data comes from [The New York Times](https://github.com/nytimes/covid-19-data)

This program uses the Vapor framework, chart.js charting javascript and a Postgres database.

Data is loaded daily into the database.
