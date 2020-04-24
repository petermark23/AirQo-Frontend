import React from 'react';
import clsx from 'clsx';
import PropTypes from 'prop-types';
import { makeStyles } from '@material-ui/styles';
import { Card, CardContent, Grid,Button, ExpansionPanel, 
  ExpansionPanelSummary,ExpansionPanelDetails} from '@material-ui/core';
import Select from 'react-select';
import { useEffect, useState } from 'react';
import DateFnsUtils from '@date-io/date-fns';
import {
  MuiPickersUtilsProvider,
  KeyboardTimePicker,
  KeyboardDatePicker,
} from '@material-ui/pickers';
import axios from 'axios';
import 'chartjs-plugin-annotation';
import {CustomDisplayChart} from '../index'
import palette from 'theme/palette';
import Typography from '@material-ui/core/Typography';
import ExpandMoreIcon from '@material-ui/icons/ExpandMore';


const useStyles = makeStyles(theme => ({
  root: {
    height: '100%'
  },
  
  avatar: {
    backgroundColor: theme.palette.success.main,
    height: 56,
    width: 56
  },
  
}));



const CustomisableChart = props => {
  const { className, ...rest } = props;

  const classes = useStyles();

  
  const [selectedDate, setSelectedStartDate] = useState(new Date());

  const handleDateChange = (date) => {
    setSelectedStartDate(date);
  };

  const [selectedEndDate, setSelectedEndDate] = useState(new Date());

  const handleEndDateChange = (date) => {
    setSelectedEndDate(date);
  };

  const [filterLocations,setFilterLocations] = useState([]);
  
  useEffect(() => {
    fetch('http://127.0.0.1:5000/api/v1/dashboard/monitoringsites/locations?organisation_name=KCCA')
      .then(res => res.json())
      .then((filterLocationsData) => {
        setFilterLocations(filterLocationsData.airquality_monitoring_sites)
      })
      .catch(console.log)
  },[]);
 
  const filterLocationsOptions = filterLocations
  
  const [values, setReactSelectValue] = useState({ selectedOption: [] });

  const handleMultiChange = selectedOption => {
    //setValue('reactSelect', selectedOption);
    setReactSelectValue({ selectedOption });
  }

  const chartTypeOptions = [
    { value: 'line', label: 'Line' },
    { value: 'bar', label: 'Bar' },
    { value: 'pie', label: 'Pie' }
  ];

  const [selectedChart, setSelectedChartType] =  useState();

  const handleChartTypeChange = selectedChartType => {
    setSelectedChartType(selectedChartType);
  };

  const frequencyOptions = [
    { value: 'hourly', label: 'Hourly' },
    { value: 'daily', label: 'Daily' },
    { value: 'monthly', label: 'Monthly' }
  ];

  const [selectedFrequency, setSelectedFrequency] =  useState();

  const handleFrequencyChange = selectedFrequencyOption => {
    setSelectedFrequency(selectedFrequencyOption);
  };

  const pollutantOptions = [
    { value: 'PM 2.5', label: 'PM 2.5' },
    { value: 'PM 10', label: 'PM 10' },
    { value: 'NO2', label: 'NO2' }
  ];

  const [selectedPollutant, setSelectedPollutant] =  useState();

  const handlePollutantChange = selectedPollutantOption => {
    setSelectedPollutant(selectedPollutantOption);
  };

  const [customGraphData, setCustomisedGraphData] = useState([]);

  useEffect(() => {
    axios.get('http://127.0.0.1:5000/api/v1/dashboard/customisedchart/random')
      .then(res => res.data)
      .then((customisedChartData) => {
        setCustomisedGraphData(customisedChartData)
        console.log(customisedChartData)
      })
      .catch(console.log)
  },[]);

  
  let  handleSubmit = (e) => {
    e.preventDefault();
    
    let filter ={ 
      locations: values.selectedOption,
      startDate:  selectedDate,
      endDate:  selectedEndDate,
      chartType:  selectedChart.value,
      frequency:  selectedFrequency.value,
      pollutant: selectedPollutant.value,
      organisation_name: 'KCCA'     
    }
    //console.log(JSON.stringify(filter));

    axios.post(
      'http://127.0.0.1:5000/api/v1/dashboard/customisedchart', 
      JSON.stringify(filter),
      { headers: { 'Content-Type': 'application/json' } }
    ).then(res => res.data)
      .then((customisedChartData) => {
        setCustomisedGraphData(customisedChartData)    

      }).catch(
        console.log
      )    
  }

 
  const customisedGraphData = {
    chart_type: customGraphData.results? customGraphData.results[0].chart_type:null,
    labels:  customGraphData.results? customGraphData.results[0].chart_data.labels:null, 
    
    datasets: customGraphData.datasets
  }

   
  const options= {
    annotation: {
      annotations: [{
        type: 'line',
        mode: 'horizontal',
        scaleID: 'y-axis-0',
        value: 25,
        borderColor: palette.text.secondary,
        borderWidth: 2,
        label: {
          enabled: true,
          content: 'WHO LIMIT',
          //backgroundColor: palette.white,
          titleFontColor: palette.text.primary,
          bodyFontColor: palette.text.primary,
          position:'right'
        },
        
      }]
    },
    responsive: true,
    maintainAspectRatio: false,
    animation: false,
    legend: { display: true },
    cornerRadius: 0,
    tooltips: {
      enabled: true,
      mode: 'index',
      intersect: false,
      borderWidth: 1,
      borderColor: palette.divider,
      backgroundColor: palette.white,
      titleFontColor: palette.text.primary,
      bodyFontColor: palette.text.secondary,
      footerFontColor: palette.text.secondary
    },
    layout: { padding: 0 },
    scales: {
      xAxes: [
        {
          barThickness: 12,
          maxBarThickness: 10,
          barPercentage: 0.5,
          categoryPercentage: 0.5,
          ticks: {
            fontColor: palette.text.secondary
          },
          gridLines: {
            display: false,
            drawBorder: false
          },
          scaleLabel: {
            display: true,
            labelString: 'Date'
          }

        }
      ],
      yAxes: [
        {
          ticks: {
            fontColor: palette.text.secondary,
            beginAtZero: true,
            min: 0
          },
          gridLines: {
            borderDash: [2],
            borderDashOffset: [2],
            color: palette.divider,
            drawBorder: false,
            zeroLineBorderDash: [2],
            zeroLineBorderDashOffset: [2],
            zeroLineColor: palette.divider
          },
          scaleLabel: {
            display: true,
            labelString: 'PM2.5(µg/m3)'
          }
        }
      ]
    }
  };

  
  
  return (
    <Card
      {...rest}
      className={clsx(classes.root, className)}
    >
      <CardContent>
                
        <Grid
          container
          spacing={1}
        >
          <Grid
            item
            lg={12}
            sm={12}
            xl={12}
            xs={12}
          >           
           
            
             
            <CustomDisplayChart 
              chart_type={customisedGraphData.chart_type} 
              customisedGraphData={customisedGraphData}
              options={options}
            />
            
          </Grid>
        
          <Grid
            item
            lg={12}
            sm={12}
            xl={12}
            xs={12}
            
          >        
            <ExpansionPanel>
              <ExpansionPanelSummary
                expandIcon={<ExpandMoreIcon />}
                aria-controls="panel1a-content"
                id="panel1a-header"
              >
                Customise
              </ExpansionPanelSummary>
              <ExpansionPanelDetails>
                <form onSubmit={handleSubmit}>             
                  
                  <Grid
                    container
                    spacing={1}
                  >             
                    <Grid
                      item
                      md={3}
                      xs={6}
                    >
                      <Select
                        fullWidth
                        className="reactSelect"
                        name="location"
                        placeholder="Location(s)"
                        value={values.selectedOption}
                        options={filterLocationsOptions}
                        onChange={handleMultiChange}
                        isMulti
                        variant="outlined"
                        margin="dense"
                        required
                      />
                    </Grid>

                    <Grid
                      item
                      md={3}
                      xs={6}
                    >                
                      <Select
                        fullWidth
                        label="Chart Type"
                        className="reactSelect"
                        name="chart-type"
                        placeholder="Chart Type"
                        value={selectedChart}
                        options={chartTypeOptions}
                        onChange={handleChartTypeChange}    
                        variant="outlined"
                        margin="dense" 
                        required         
                      />
                    </Grid>
                    
                    <Grid
                      item
                      md={3}
                      xs={6}
                    >     
                      <Select
                        fullWidth
                        label ="Frequency"
                        className=""
                        name="chart-frequency"
                        placeholder="Frequency"
                        value={selectedFrequency}
                        options={frequencyOptions}
                        onChange={handleFrequencyChange}
                        variant="outlined"
                        margin="dense"   
                        required           
                      />
                    </Grid>
                    <Grid
                      item
                      md={3}
                      xs={6}
                    >     
                      <Select
                        fullWidth
                        label="Pollutant"
                        className=""
                        name="pollutant"
                        placeholder="Pollutant"
                        value={selectedPollutant}
                        options={pollutantOptions}
                        onChange={handlePollutantChange}
                        variant="outlined"
                        margin="dense"  
                        required            
                      />
                    </Grid>

                    <Grid
                      item
                      md={12}
                      xs={12}
                    >
                      <MuiPickersUtilsProvider utils={DateFnsUtils}>
                        <Grid 
                          container 
                          spacing={1}
                        >
                          <Grid
                            item
                            lg={3}
                            md={3}
                            sm={6}
                            xl={3}
                            xs={12}
                          >
                            <KeyboardDatePicker                     
                              disableToolbar
                              variant="inline"
                              format="MM/dd/yyyy"
                              margin="normal"
                              id="date-picker-inline"
                              label="Start Date"
                              value={selectedDate}
                              onChange={handleDateChange}
                              KeyboardButtonProps={{
                                'aria-label': 'change date',
                              }}
                              required
                            />  
                          </Grid>  
                          <Grid
                            item
                            lg={3}
                            md={3}
                            sm={6}
                            xl={3}
                            xs={12}
                          >            
                            <KeyboardTimePicker                     
                              disableToolbar
                              variant="inline"
                              margin="normal"
                              id="time-picker"
                              label="Start Time Picker "
                              value={selectedDate}
                              onChange={handleDateChange}
                              KeyboardButtonProps={{
                                'aria-label': 'change time',
                              }}  
                              required                    
                            />
                          </Grid>

                          <Grid
                            item
                            lg={3}
                            md={3}
                            sm={6}
                            xl={3}
                            xs={12}
                          >
                            <KeyboardDatePicker                      
                              disableToolbar
                              variant="inline"
                              format="MM/dd/yyyy"
                              margin="normal"
                              id="date-picker-inline"
                              label="End Date"
                              value={selectedEndDate}
                              onChange={handleEndDateChange}
                              KeyboardButtonProps={{
                                'aria-label': 'change end date',
                              }}
                              required
                            /> 
                          </Grid> 
                          <Grid
                            item
                            lg={3}
                            md={3}
                            sm={6}
                            xl={3}
                            xs={12}
                          >              
                            <KeyboardTimePicker                      
                              disableToolbar
                              variant="inline"
                              margin="normal"
                              id="time-picker"
                              label="End Time Picker "
                              value={selectedEndDate}
                              onChange={handleEndDateChange}
                              KeyboardButtonProps={{
                                'aria-label': 'change end time',
                              }}
                              required
                            />
                          </Grid>
                        </Grid>
                      </MuiPickersUtilsProvider>
                    </Grid>             
                
                    
                
                    <Button 
                      variant="contained" 
                      color="primary"              
                      type="submit"
                    > Generate Graph
                    </Button>
                    
                  </Grid>
                </form>            
              </ExpansionPanelDetails>
            </ExpansionPanel>
                 
          </Grid>
          
        </Grid>

      </CardContent>
    </Card>
  );
};

CustomisableChart.propTypes = {
  className: PropTypes.string
};

export default CustomisableChart;
