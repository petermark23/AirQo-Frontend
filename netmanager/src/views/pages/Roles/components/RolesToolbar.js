/* eslint-disable */
import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import clsx from 'clsx';
import { makeStyles } from '@material-ui/styles';
import {
  Button,
  TextField,
  DialogTitle,
  DialogContent,
  Dialog,
  DialogActions
} from '@material-ui/core';
import { updateMainAlert } from 'redux/MainAlert/operations';
import { addUserRoleApi, assignPermissionsToRoleApi } from '../../../apis/accessControl';
import { loadUserRoles } from 'redux/AccessControl/operations';
import OutlinedSelect from '../../../components/CustomSelects/OutlinedSelect';

const useStyles = makeStyles((theme) => ({
  root: {
    '&$error': {
      color: 'red'
    }
  },
  row: {
    height: '42px',
    display: 'flex',
    alignItems: 'center',
    marginTop: theme.spacing(1)
  },
  spacer: {
    flexGrow: 1
  },
  importButton: {
    marginRight: theme.spacing(1)
  },
  exportButton: {
    marginRight: theme.spacing(1)
  },
  searchInput: {
    marginRight: theme.spacing(1)
  },
  container: {
    display: 'flex',
    flexWrap: 'wrap'
  },
  textField: {
    marginLeft: theme.spacing.unit,
    marginRight: theme.spacing.unit
  },
  dense: {
    marginTop: 16
  },
  menu: {
    width: 200
  },
  modelWidth: {
    minWidth: 450
  }
}));

const RolesToolbar = (props) => {
  const classes = useStyles();
  const { className, mappeduserState, mappedErrors, permissions, ...rest } = props;
  const dispatch = useDispatch();
  const initialState = {
    roleName: ''
  };
  const [form, setState] = useState(initialState);
  const [open, setOpen] = useState(false);
  const [selectedPermissions, setSelectedPermissions] = useState([]);

  const permissionOptions =
    permissions &&
    permissions.map((permission) => {
      return {
        value: permission._id,
        label: permission.permission
      };
    });

  const clearState = () => {
    setState({ ...initialState });
  };

  const handleClickOpen = () => {
    setOpen(true);
  };

  const handleClose = () => {
    setOpen(false);
    setState(initialState);
  };

  const onChange = (e) => {
    e.preventDefault();
    const { id, value } = e.target;

    setState({
      ...form,
      [id]: value
    });
  };

  const onSubmit = (e) => {
    e.preventDefault();
    setOpen(false);
    const body = {
      role_code: form.roleName,
      role_name: form.roleName
    };
    addUserRoleApi(body)
      .then((resData) => {
        // assign permissions to role
        assignPermissionsToRoleApi(
          resData.roles._id,
          selectedPermissions.map((permission) => permission.value)
        )
          .then((resData) => {
            dispatch(loadUserRoles());
            setState(initialState);
            dispatch(
              updateMainAlert({
                message: 'New role added successfully',
                show: true,
                severity: 'success'
              })
            );
          })
          .catch((error) => {
            dispatch(
              updateMainAlert({
                message: error.response && error.response.data && error.response.data.message,
                show: true,
                severity: 'error'
              })
            );
          });
      })
      .catch((error) => {
        dispatch(
          updateMainAlert({
            message: error.response && error.response.data && error.response.data.message,
            show: true,
            severity: 'error'
          })
        );
      });
  };

  useEffect(() => {
    clearState();
  }, []);

  return (
    <div className={clsx(classes.root, className)}>
      <div className={classes.row}>
        <span className={classes.spacer} />
        <div>
          <Button variant="contained" color="primary" onClick={handleClickOpen}>
            Add Role
          </Button>
          <Dialog open={open} onClose={handleClose} aria-labelledby="form-dialog-title">
            <DialogTitle id="form-dialog-title">Add Role</DialogTitle>
            <DialogContent>
              <div className={classes.modelWidth}>
                <TextField
                  margin="dense"
                  id="roleName"
                  name="role_name"
                  type="text"
                  label="Role"
                  onChange={onChange}
                  variant="outlined"
                  value={form.roleName}
                  fullWidth
                  style={{ marginBottom: '30px' }}
                  required
                />

                <OutlinedSelect
                  className="reactSelect"
                  label="Permissions"
                  onChange={(options) => setSelectedPermissions(options)}
                  options={permissionOptions}
                  value={selectedPermissions}
                  fullWidth
                  isMulti
                  scrollable
                  height={'100px'}
                  required
                />
              </div>
            </DialogContent>

            <DialogActions>
              <div>
                <Button onClick={handleClose} color="primary" variant="outlined">
                  Cancel
                </Button>
                <Button
                  style={{ margin: '0 15px' }}
                  onClick={onSubmit}
                  color="primary"
                  variant="contained"
                >
                  Submit
                </Button>
              </div>
            </DialogActions>
          </Dialog>
        </div>
      </div>
    </div>
  );
};

export default RolesToolbar;
