import React, { useState, useEffect } from 'react';
import { useDispatch } from 'react-redux';
import clsx from 'clsx';
import PropTypes from 'prop-types';
import { makeStyles } from '@material-ui/styles';
import {
  Card,
  Avatar,
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  TextField,
  CircularProgress,
  Collapse
} from '@material-ui/core';

import { Alert, AlertTitle } from '@material-ui/lab';

import { Check } from '@material-ui/icons';
import { getInitials } from 'utils/users';
import { formatDateString } from 'utils/dateTime';
import CandidateEditForm from 'views/pages/UserList/components/UserEditForm';
import CustomMaterialTable from 'views/components/Table/CustomMaterialTable';
import usersStateConnector from 'views/stateConnectors/usersStateConnector';
import ConfirmDialog from 'views/containers/ConfirmDialog';
import {
  confirmCandidateApi,
  deleteCandidateApi,
  updateCandidateApi,
  sendUserFeedbackApi
} from 'views/apis/authService';
import { updateMainAlert } from 'redux/MainAlert/operations';

const useStyles = makeStyles((theme) => ({
  root: {},
  content: {
    padding: 0
  },
  inner: {
    minWidth: 1050
  },
  nameContainer: {
    display: 'flex',
    alignItems: 'center'
  },
  avatar: {
    marginRight: theme.spacing(2)
  },
  actions: {
    justifyContent: 'flex-end'
  },
  collapseContent: {
    maxHeight: 100,
    overflow: 'hidden',
    transition: 'max-height 0.3s ease-out'
  },
  expandContent: {
    maxHeight: 'none'
  },
  expandButton: {
    display: 'flex',
    justifyContent: 'flex-end'
  }
}));

const CandidatesTable = (props) => {
  const { className, mappeduserState, ...rest } = props;
  const dispatch = useDispatch();
  const [open, setOpen] = useState(false);
  const [openDel, setOpenDel] = useState(false);
  const [currentCandidate, setCurrentCandidate] = useState(null);

  const [openNewMessagePopup, setOpenNewMessagePopup] = useState(false);

  const [userFeedbackMessage, setUserFeedbackMessage] = useState('');
  const [messageSubject, setMessageSubject] = useState('');
  const [isLoading, setLoading] = useState(false);

  const users = mappeduserState.candidates;
  const editCandidate = mappeduserState.userToEdit;
  const userToDelete = mappeduserState.userToDelete;

  // The methods
  const hideEditDialog = () => {
    props.mappedhideEditDialog();
  };

  const submitEditCandidate = (e) => {
    e.preventDefault();
    const editForm = document.getElementById('EditCandidateForm');
    const userData = props.mappeduserState;
    if (editForm.userName.value !== '') {
      const data = new FormData();
      data.append('id', userData.userToEdit._id);
      data.append('userName', editForm.userName.value);
      data.append('firstName', editForm.firstName.value);
      data.append('lastName', editForm.lastName.value);
      data.append('email', editForm.email.value);
      //add the role in the near future.
      props.mappedEditCandidate(data);
    } else {
      return;
    }
  };

  const hideDeleteDialog = () => {
    props.mappedHideDeleteDialog();
  };

  const cofirmDeleteCandidate = () => {
    props.mappedConfirmDeleteCandidate();
  };

  const handleConfirm = async (candidateId) => {
    try {
      setLoading(true);
      await confirmCandidateApi(candidateId);
      setLoading(false);
      setOpen(false);
      dispatch(updateMainAlert('Candidate confirmed successfully', 'success'));
    } catch (error) {
      setLoading(false);
      setOpen(false);
      dispatch(
        updateMainAlert('Failed to confirm candidate. Please try again later.', 'error')
      );
    }
  };

  const handleDelete = async (candidateId) => {
    try {
      setLoading(true);
      await deleteCandidateApi(candidateId);
      setLoading(false);
      setOpenDel(false);
      dispatch(updateMainAlert('Candidate deleted successfully', 'success'));
    } catch (error) {
      setLoading(false);
      setOpenDel(false);
      dispatch(updateMainAlert('Failed to delete candidate. Please try again later.', 'error'));
    }
  };

  const handleSendFeedback = async () => {
    try {
      setLoading(true);
      await sendUserFeedbackApi(currentCandidate._id, messageSubject, userFeedbackMessage);
      setLoading(false);
      setOpenNewMessagePopup(false);
      setUserFeedbackMessage('');
      setMessageSubject('');
      dispatch(updateMainAlert('Feedback sent successfully', 'success'));
    } catch (error) {
      setLoading(false);
      setOpenNewMessagePopup(false);
      dispatch(
        updateMainAlert('Failed to send feedback. Please try again later.', 'error')
      );
    }
  };

  const handleOpenSendFeedback = (candidate) => {
    setCurrentCandidate(candidate);
    setOpenNewMessagePopup(true);
  };

  const handleExpandClick = async (candidateId) => {
    setOpen((prevOpen) => !prevOpen);
    if (!open) {
      try {
        setLoading(true);
        await props.mappedFetchFeedback(candidateId);
        setLoading(false);
      } catch (error) {
        setLoading(false);
        dispatch(updateMainAlert('Failed to fetch feedback. Please try again later.', 'error'));
      }
    }
  };

  useEffect(() => {
    if (editCandidate) {
      setOpen(true);
    }
  }, [editCandidate]);

  useEffect(() => {
    if (userToDelete) {
      setOpenDel(true);
    }
  }, [userToDelete]);

  const classes = useStyles();

  return (
    <Card {...rest} className={clsx(classes.root, className)}>
      <CustomMaterialTable
        columns={[
          {
            title: 'Name',
            field: 'name',
            render: (candidate) => (
              <div className={classes.nameContainer}>
                <Avatar
                  className={classes.avatar}
                  src={candidate.avatar}
                  alt="Candidate Avatar"
                >
                  {getInitials(candidate.firstName, candidate.lastName)}
                </Avatar>
                <Typography variant="body1">
                  {`${candidate.firstName} ${candidate.lastName}`}
                </Typography>
              </div>
            )
          },
          {
            title: 'Email',
            field: 'email'
          },
          {
            title: 'Phone',
            field: 'phone'
          },
          {
            title: 'Description',
            field: 'description',
            render: (candidate) => (
              <>
                <div
                  className={clsx(classes.collapseContent, {
                    [classes.expandContent]: open
                  })}
                >
                  {candidate.description}
                </div>
                {candidate.description.length > 100 && (
                  <div className={classes.expandButton}>
                    <Button
                      size="small"
                      color="primary"
                      onClick={() => handleExpandClick(candidate._id)}
                    >
                      {open ? 'Collapse' : 'Expand'}
                    </Button>
                  </div>
                )}
              </>
            )
          },
          {
            title: 'Date Applied',
            field: 'createdAt',
            render: (candidate) => formatDateString(candidate.createdAt)
          },
          {
            title: 'Actions',
            field: 'actions',
            render: (candidate) => (
              <>
                {!candidate.isConfirmed && (
                  <Button
                    color="primary"
                    variant="contained"
                    onClick={() => handleConfirm(candidate._id)}
                    disabled={isLoading}
                  >
                    {isLoading ? (
                      <CircularProgress size={20} color="inherit" />
                    ) : (
                      'Confirm'
                    )}
                  </Button>
                )}
                <Button
                  color="primary"
                  variant="outlined"
                  onClick={() => handleOpenSendFeedback(candidate)}
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <CircularProgress size={20} color="inherit" />
                  ) : (
                    'Send Feedback'
                  )}
                </Button>
                <Button
                  color="secondary"
                  variant="outlined"
                  onClick={() => handleDelete(candidate._id)}
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <CircularProgress size={20} color="inherit" />
                  ) : (
                    'Delete'
                  )}
                </Button>
              </>
            )
          }
        ]}
        data={users}
        title="Candidates"
      />

      {/* Edit Candidate Dialog */}
      {editCandidate && (
        <CandidateEditForm
          hideEditDialog={hideEditDialog}
          submitEditCandidate={submitEditCandidate}
          userToEdit={editCandidate}
          isLoading={mappeduserState.isLoading}
        />
      )}

      {/* Delete User Dialog */}
      <ConfirmDialog
        title="Delete Candidate"
        open={openDel}
        hideDeleteDialog={hideDeleteDialog}
        confirmDeleteAction={cofirmDeleteCandidate}
        isLoading={isLoading}
      >
        Are you sure you want to delete this candidate?
      </ConfirmDialog>

      {/* Send Feedback Dialog */}
      <Dialog
        open={openNewMessagePopup}
        onClose={() => setOpenNewMessagePopup(false)}
        aria-labelledby="form-dialog-title"
      >
        <DialogTitle id="form-dialog-title">Send Feedback</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Send feedback to {currentCandidate && currentCandidate.firstName}{' '}
            {currentCandidate && currentCandidate.lastName}
          </DialogContentText>
          <TextField
            autoFocus
            margin="dense"
            id="messageSubject"
            label="Subject"
            type="text"
            fullWidth
            value={messageSubject}
            onChange={(e) => setMessageSubject(e.target.value)}
          />
          <TextField
            margin="dense"
            id="userFeedbackMessage"
            label="Message"
            type="text"
            multiline
            rows={4}
            fullWidth
            value={userFeedbackMessage}
            onChange={(e) => setUserFeedbackMessage(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenNewMessagePopup(false)} color="primary">
            Cancel
          </Button>
          <Button
            onClick={handleSendFeedback}
            color="primary"
            variant="contained"
            disabled={isLoading}
          >
            {isLoading ? <CircularProgress size={20} color="inherit" /> : 'Send'}
          </Button>
        </DialogActions>
      </Dialog>
    </Card>
  );
};

CandidatesTable.propTypes = {
  className: PropTypes.string
};

export default usersStateConnector(CandidatesTable);
