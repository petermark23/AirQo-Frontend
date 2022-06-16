import React from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import { Provider } from 'react-redux';
import HomePage from 'src/pages/HomePage';
import ResearchPage from 'src/pages/ResearchPage';
import Press from 'src/pages/Press/Press';
import { loadAirQloudSummaryData } from 'reduxStore/AirQlouds/operations';
import Terms from './src/pages/Legal/Terms';
import CommunityPage from './src/pages/CommunityPage';
import AboutUsPage from './src/pages/AboutUsPage';
import ContactUsPage from './src/pages/ContactUs/ContactUs';
import ContactForm from './src/pages/ContactUs/ContactForm';
import AfricanCitiesPage, { ContentUganda, ContentKenya } from './src/pages/AfricanCitiesPage';
import GetInvolved from './src/pages/GetInvolved';
import Register from './src/pages/GetInvolved/Register';
import CheckMail from './src/pages/GetInvolved/CheckMail';
import store from './store';
import ExploreData, { DownloadApp, GetStarted, GetStartedForm, IndividualForm, InstitutionForm, CreateAccountForm, ConfirmExploreDataMail } from './src/pages/ExploreData';

store.dispatch(loadAirQloudSummaryData());

const App = () => (
    <Provider store={store}>
        <Router>
            <Routes>
                <Route path="/" element={<HomePage />} />
                <Route path="/solutions/research" element={<ResearchPage />} />
                <Route path="/solutions/communities" element={<CommunityPage />} />
                <Route path="/solutions/african-cities" element={<AfricanCitiesPage />}>
                    <Route path="uganda" element={<ContentUganda />} />
                    <Route path="kenya" element={<ContentKenya />} />
                </Route>
                <Route path="/about-us" element={<AboutUsPage />} />
                <Route path="/press" element={<Press />} />
                <Route path="/terms" element={<Terms />} />
                <Route path="/contact" element={<ContactUsPage />} />
                <Route path="/contact/form" element={<ContactForm />} />
                <Route path="/get-involved" element={<GetInvolved />} />
                <Route path="/get-involved/register" element={<Register />} />
                <Route path="/get-involved/check-mail" element={<CheckMail />} />
                <Route path="/explore-data" element={<ExploreData />} />
                <Route path="/explore-data/download-apps" element={<DownloadApp />} />
                <Route path="/explore-data/get-started" element={<GetStarted />} />
                <Route path="/explore-data/get-started/account" element={<GetStartedForm />} />
                <Route path="/explore-data/get-started/account/individual" element={<IndividualForm />} />
                <Route path="/explore-data/get-started/account/institution" element={<InstitutionForm />} />
                <Route path="/explore-data/get-started/account/register" element={<CreateAccountForm />} />
                <Route path="/explore-data/get-started/account/check-mail" element={<ConfirmExploreDataMail />} />
            </Routes>
        </Router>
    </Provider>
);

export default App;
