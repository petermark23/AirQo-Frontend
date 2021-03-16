/* eslint-disable */
import React, { Suspense, lazy } from "react";
import "./App.css";
import { BrowserRouter as Router, Route, Switch } from "react-router-dom";

import jwt_decode from "jwt-decode";
import setAuthToken from "./utils/setAuthToken";
import { setCurrentUser, logoutUser } from "./redux/Join/actions";

import { Provider } from "react-redux";
import store from "./store";
import { ThemeProvider } from "@material-ui/styles";
import theme from "./assets/theme";
import PrivateRoute from "./views/components/PrivateRoute/PrivateRoute";
import { setOrganization } from "./redux/Join/actions";
import { useJiraHelpDesk } from "utils/customHooks";

// core imports. imported on initial page load
import Dashboard from "./views/components/Dashboard/Dashboard";
import Devices from "./views/components/DataDisplay/Devices";
import { Download as DownloadView } from "./views/pages/Download";
import Landing from "./views/layouts/Landing";
import { Main as MainLayout, Minimal as MinimalLayout } from "views/layouts/";
import { NotFound as NotFoundView } from "./views/pages/NotFound";

// lazy imports
const Account = lazy(() => import("./views/pages/Account"));
const AnalyticsDashboard = lazy(() => import("./views/pages/Dashboard"));
const DeviceView = lazy(() => import("./views/components/DataDisplay/DeviceView"));
const Manager = lazy(() => import("./views/components/DataDisplay/DeviceManagement"));
const Map = lazy(() => import("./views/components/Map"));
const OverlayMap = lazy(() => import("./views/pages/Map"));
const ForgotPassword = lazy(() => import("./views/pages/ForgotPassword"));
const ResetPassword = lazy(() => import("./views/pages/ResetPassword"));
const Login = lazy(() => import("./views/pages/SignUp/Login"));
const Register  = lazy(() => import("./views/pages/SignUp/Register"));
const UserList = lazy(() => import("./views/pages/UserList"));
const CandidateList = lazy(() => import("./views/pages/CandidateList"));
const Settings = lazy(() => import("./views/pages/Settings"));
const LocationList = lazy(() => import("./views/components/LocationList/LocationList"));
const LocationRegister  = lazy(() => import("./views/components/LocationList/LocationRegister"));
const LocationView = lazy(() => import("./views/components/LocationList/LocationView"));
const LocationEdit = lazy(() => import("./views/components/LocationList/LocationEdit"));

// Check for token to keep user logged in
if (localStorage.jwtToken) {
  // Set auth token header auth
  const token = localStorage.jwtToken;
  setAuthToken(token);
  // Decode token and get user info and exp
  const decoded = jwt_decode(token);
  let currentUser = decoded;

  if (localStorage.currentUser) {
    try {
      currentUser = JSON.parse(localStorage.currentUser);
    } catch (error) {}
  }
  // Set user and isAuthenticated
  store.dispatch(setCurrentUser(currentUser));
  // Check for expired token
  const currentTime = Date.now() / 1000; // to get in milliseconds
  if (decoded.exp < currentTime) {
    // Logout user
    store.dispatch(logoutUser());
    // Redirect to the landing page
    window.location.href = "./";
  }
  store.dispatch(setOrganization());
}

const App = () => {

  useJiraHelpDesk();

  return (
    <Provider store={store}>
      <ThemeProvider theme={theme}>
        <Router>
          <div className="App">
            <Route exact path="/" component={Landing} />

            <Suspense fallback={<div>Loading...</div>}>
              <Route exact path="/login" component={Login} />
              <Route exact path="/forgot" component={ForgotPassword} />
              <Route exact path="/reset" component={ResetPassword} />
              <Route
                exact
                path="/request-access"
                component={Register}
              />
            </Suspense>
            <Suspense fallback={<div>Loading 2...</div>}>
              <PrivateRoute
                exact
                path="/dashboard"
                component={AnalyticsDashboard}
                layout={MainLayout}
              />
              <PrivateRoute
                exact
                path="/admin/users"
                component={UserList}
                layout={MainLayout}
              />
              <PrivateRoute
                component={CandidateList}
                exact
                layout={MainLayout}
                path="/candidates"
              />
              <PrivateRoute
                component={Settings}
                exact
                layout={MainLayout}
                path="/settings"
              />

              <PrivateRoute
                path="/device/:deviceName"
                component={DeviceView}
                layout={MainLayout}
              />
              <PrivateRoute
                exact
                path="/locate"
                component={Map}
                layout={MainLayout}
              />
              <PrivateRoute
                exact
                path="/map"
                component={OverlayMap}
                layout={MainLayout}
              />
              <PrivateRoute
                component={Account}
                exact
                layout={MainLayout}
                path="/account"
              />
              <PrivateRoute
                exact
                path="/manager"
                component={Manager}
                layout={MainLayout}
              />
              <PrivateRoute
                extact
                path="/location"
                component={LocationList}
                layout={MainLayout}
              />
              <PrivateRoute
                exact
                path="/edit/:loc_ref"
                component={LocationEdit}
                layout={MainLayout}
              />
              <PrivateRoute
                exact
                path="/locations/:loc_ref"
                component={LocationView}
                layout={MainLayout}
              />
              <PrivateRoute
                extact
                path="/register_location"
                component={LocationRegister}
                layout={MainLayout}
              />
            </Suspense>

            <Switch>
              <PrivateRoute
                exact
                path="/overview"
                component={Dashboard}
                layout={MainLayout}
              />
              <PrivateRoute
                exact
                path="/download"
                component={DownloadView}
                layout={MainLayout}
              />
              <PrivateRoute
                extact
                path="/registry"
                component={Devices}
                layout={MainLayout}
              />
              <PrivateRoute
                component={NotFoundView}
                exact
                layout={MinimalLayout}
                path="/not-found"
              />
            </Switch>
            <div
                style={{
                  position: "fixed",
                  bottom: 0,
                  right: 0,
                  marginRight: "10px",
                  marginBottom: "20px",
            }}>
                <div id="jira-help-desk" />
            </div>
          </div>
        </Router>
      </ThemeProvider>
    </Provider>
  );
}
export default App;
