# Research Internship

This repository contains the code for a research internship under the supervision of dr. Onno Kleen at Erasmus University Rotterdam. The project considers the use of feedforward neural networks for boosting parametric forecasts of correlation matrices. 

The first step in the project is to investigate whether the method works empirically. For this we collect data from the Center for Research in Security Prices (CRSP) database. The code for the collection of the data is:
- Collection.R
- Collection2.R

The code for preprocessing the collected data is:
- Preprocessing.ipynb
- Preprocessing2.ipynb

The code for exploring the computational efficiency of using the new parameterization of the correlation matrices is:
- Transformation.ipynb
  
The code for forecasting correlation matrices using several feedforward neural networks, i.e. nonparametrically boosting a lagged forecast of the correlation matrices, is:
- Forecast.ipynb

The code for boosting several parametric forecasts using feedforward neural networks is:
- Boost.ipynb
