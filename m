import api from './ApiClient';
import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  Button,
  Alert,
  Snackbar,
  InputBase
} from '@mui/material';
import { RequiredInformationHeader } from './RequiredInformationHeader';
import { CompOffLayout } from './CompOffLayout.tsx';
import CompOffReport from './CompOffReport';

const CompOffManagerApprove = ({ onBack, submittedRequests = [] }) => {
  const [showReport, setShowReport] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [rmRemarks, setRmRemarks] = useState({});
  const [approvalStatus, setApprovalStatus] = useState({});
  const manager_user_id = 22454221;
  useEffect(() => {
    const masterid = 123; // Replace if dynamic
    api.get('/api/PreCompOffRequest/GetCompoffRequestDetails', {
      params: { masterid }
    })
      .then((res) => console.log('Request Details:', res.data))
      .catch((err) => console.error('Error fetching details:', err));
  }, []);

  const approvalRequests = submittedRequests.map((request) => ({
    id: request.id,
    employeeId: request.employeeId || '22454221',
    employeename: request.employeeName || 'Karandeep Sahni',
    requestDate: request.requestDate,
    reason: request.reason,
    initiationType: request.initiationType || 'forMe',
    reportee: request.reportee || ''
  }));
  const hasReporteeRequests = approvalRequests.some(req => req.initiationType === 'forMyReportee');

  const handleRmRemarksChange = (id, value) => {
    setRmRemarks(prev => ({ ...prev, [id]: value }));
  };
  const handleApproveRequest = (requestId) => {
    if (!rmRemarks[requestId]?.trim()) {
      setSnackbar({ open: true, message: 'Please add remarks before approving', severity: 'warning' });
      return;
    }
    const request = approvalRequests.find(req => req.id === requestId);
    if (!request) {   
      console.error("Request object not found for ID:", requestId);   
      return; 
    }
    const payload = {
      preApprovalID: parseInt(requestId),
      employeeID: request.employeeId,
      employeeName: request.employeeName,
      compRefDate: new Date(request.requestDate).toISOString(),
      reason: request.reason,
      rmRemarks: rmRemarks[requestId],
      approvedBy: manager_user_id
    };
    console.log("Submitting approval payload:", payload);
    api.post('/api/PreCompOffRequest/UpdateManagerApproval', payload)
      .then(() => {
        setApprovalStatus(prev => ({ ...prev, [requestId]: 'approved' }));
        setSnackbar({ open: true, message: 'Request approved successfully', severity: 'success' });
      })
      .catch((err) => {
        console.error('Approval failed:', err?.response?.data || err.message);
        setSnackbar({ open: true, message: 'Approval failed. Please try again.', severity: 'error' });

      });
  };

  const handleRejectRequest = (requestId) => {
    if (!rmRemarks[requestId]?.trim()) {
      setSnackbar({ open: true, message: 'Please add remarks before rejecting', severity: 'warning' });
      return;
    }
    const request = approvalRequests.find(req => req.id === requestId);
    if (!request) {   
      console.error("Request object not found for ID:", requestId);   
      return; 
    }
    const payload = {
      preApprovalID: parseInt(requestId),
      employeeID: request.employeeId,
      employeeName: request.employeeName,
      compRefDate: new Date(request.requestDate).toISOString(),
      reason: request.reason,
      rmRemarks: rmRemarks[requestId],
      approvedBy: manager_user_id
    };
    console.log("Rejecting with payload:", payload);
    api.post('/api/PreCompOffRequest/UpdateManagerApproval', payload)
      .then(() => {
        setApprovalStatus(prev => ({ ...prev, [requestId]: 'rejected' }));
        setSnackbar({ open: true, message: 'Request rejected', severity: 'error' });
      })
      .catch((err) => {
        console.error('Rejection failed:', err?.response?.data || err.message);
        setSnackbar({ open: true, message: 'Rejection failed. Please try again.', severity: 'error' });
      });
  };

  const handleTransferWorkflow = () => {
    const unprocessed = approvalRequests.filter(req => !approvalStatus[req.id]);
    if (unprocessed.length > 0) {
      setSnackbar({ open: true, message: 'Please approve or reject all requests before viewing report', severity: 'warning' });
      return;
    }
    setShowReport(true);
  };
  const handleBackFromReport = () => setShowReport(false);
  const getReportData = () => {
    return approvalRequests
      .filter(req => approvalStatus[req.id] === 'approved' || approvalStatus[req.id] === 'rejected')
      .map(req => ({ ...req, rmRemarks: rmRemarks[req.id] || '', status: approvalStatus[req.id] }));
  };
  return showReport ? (
    <CompOffReport
      onBack={handleBackFromReport}
      approvedRequests={getReportData()}
      initiationType={submittedRequests[0]?.initiationType || 'forMe'}
    />
  ) : (
    <CompOffLayout
      title="Comp off Pre Approval - (Manager Approve)"
      showBackButton={true}
      onBackClick={onBack}
    >
      <Box sx={{ bgcolor: '#F9FAFB', borderRadius: 2, p: 3, mb: 3 }}>
        <RequiredInformationHeader />
        <Box sx={{ mt: 2, mb: 2 }}>
          <Typography sx={{ fontWeight: 700, fontSize: 16 }}>Approval List</Typography>
          <Box sx={{ border: '1px solid #E5E7EB', borderRadius: '16px', bgcolor: '#FFFFFF' }}>
            <Box sx={{ display: 'flex', bgcolor: '#F1F6FB', p: 1, fontWeight: 700, fontSize: 15 }}>
              <Box sx={{ flex: 1 }}>Employee ID</Box>
              {hasReporteeRequests && <Box sx={{ flex: 1 }}>Reportee</Box>}
              <Box sx={{ flex: 1 }}>Employee Name</Box>
              <Box sx={{ flex: 1 }}>Request Date</Box>
              <Box sx={{ flex: 2 }}>Reason</Box>
              <Box sx={{ flex: 1 }}>RM Remarks</Box>
            </Box>
            {approvalRequests.length > 0 ? approvalRequests.map((req) => (
              <Box key={req.id} sx={{ display: 'flex', alignItems: 'center', borderTop: '1px solid #E5E7EB', p: 1 }}>
                <Box sx={{ flex: 1 }}>{req.employeeId}</Box>
                {hasReporteeRequests && <Box sx={{ flex: 1 }}>{req.reportee || 'N/A'}</Box>}
                <Box sx={{ flex: 1 }}>{req.employeeName}</Box>
                <Box sx={{ flex: 1 }}>{req.requestDate}</Box>
                <Box sx={{ flex: 2 }}>{req.reason}</Box>
                <Box sx={{ flex: 1, px: 1 }}>
                  <TextField
                    fullWidth multiline minRows={2} maxRows={4} size="small"
                    value={rmRemarks[req.id] || ''}
                    onChange={(e) => handleRmRemarksChange(req.id, e.target.value)}
                    placeholder="Enter your remarks here..."
                  />
                </Box>
              </Box>
            )) : (
              <Box sx={{ display: 'flex', alignItems: 'center', p: 2 }}>
                <Box sx={{ flex: 1, textAlign: 'center' }}>No requests submitted yet</Box>
              </Box>
            )}
          </Box>
        </Box>
        <Box sx={{ mt: 3, mb: 2 }}>
          <Typography sx={{ fontWeight: 700, fontSize: 14, mb: 1 }}>Comment (Max 500 Chars)</Typography>
          <InputBase
            fullWidth multiline minRows={2} maxRows={4}
            placeholder="XXX-XXX-XX-XXX-X"
            sx={{ bgcolor: '#FFFFFF', border: '1px solid #E5E7EB', borderRadius: 1, px: 2, py: 1.2 }}
          />
        </Box>
        <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 3 }}>
          <Button variant="outlined" onClick={() => {
            approvalRequests.forEach(req => {
              if (!approvalStatus[req.id]) handleRejectRequest(req.id);
            });
          }}>Reject</Button>
          <Button variant="contained" onClick={() => {
            approvalRequests.forEach(req => {
              if (!approvalStatus[req.id]) handleApproveRequest(req.id);
            });
          }}>Approve</Button>
        </Box>
      </Box>
      <Box sx={{ mt: 2, mb: 2 }}>
        <Box sx={{
          display: 'flex', justifyContent: 'space-between', bgcolor: '#F8FAFC',
          borderRadius: '8px', px: 3, py: 2, cursor: 'pointer'
        }} onClick={handleTransferWorkflow}>
          <Typography sx={{ fontWeight: 500 }}>Transfer Workflow</Typography>
          <Typography>→</Typography>
        </Box>
      </Box>
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'top', horizontal: 'right' }}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          variant="filled"
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </CompOffLayout>
  );
};
export default CompOffManagerApprove;
