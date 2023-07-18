import { AUTH_URL, GOOGLE_AUTH_URL } from '../urls/authentication';
import axios from 'axios';

export const postUserCreationDetails = async (data) =>
  await axios.post(AUTH_URL, data).then((response) => response.data);

export const getGoogleAuthDetails = async () => {
  try {
    const response = await axios.get(GOOGLE_AUTH_URL);
    if (response.status === 302) {
      const redirectUrl = response.headers.location;
      window.location.href = redirectUrl;
    }
  } catch (error) {
    alert(error)
  }
};
