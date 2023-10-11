import React, { useState, useEffect } from 'react';
import './App.css';

function CertificateList() {
  const [certificates, setCertificates] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    // Fetch your certificate data here and set it in the certificates state
    // For example, you can fetch it from a JSON file or an API
    // Replace this with your actual data-fetching logic
    const fetchData = async () => {
      try {
        const response = await fetch('/certificate_inventory.json');
        if (!response.ok) {
          throw new Error('Failed to fetch data');
        }
        const data = await response.json();
        setCertificates(data);
      } catch (error) {
        console.error('Error fetching data:', error);
      }
    };

    fetchData();
  }, []);

  const filteredCertificates = certificates.filter((certificate) =>
    certificate.Subject.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="container">
      <div className="row">
      <div className="col p-4">
      <h1>Certificate List</h1>

      <div className="p-3 mb-3">
      <input
        type="text"
        className="form-control form-control-lg"
        placeholder="Search by Subject"
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
      />
      </div>

      <div className="table-responsive">
      <table className="table table-striped table-hover table-responsive">
        <thead>
          <tr>
            <th>Path</th>
            <th>Subject</th>
            <th>Issuer</th>
            <th>Thumbprint</th>
            <th>Expiration Date</th>
          </tr>
        </thead>
        <tbody>
          {filteredCertificates.map((certificate, index) => (
            <tr key={index}>
              <td>{certificate.Path}</td>
              <td>{certificate.Subject}</td>
              <td>{certificate.Issuer}</td>
              <td>{certificate.Thumbprint}</td>
              <td>{certificate.ExpirationDate}</td>
            </tr>
          ))}
        </tbody>
      </table>
      </div>

      {/* <ul>
        {filteredCertificates.map((certificate, index) => (
          <li key={index}>
            <strong>Path:</strong> {certificate.Path}<br />
            <strong>Subject:</strong> {certificate.Subject}<br />
            <strong>Issuer:</strong> {certificate.Issuer}<br />
            <strong>Thumbprint:</strong> {certificate.Thumbprint}<br />
            <strong>Expiration Date:</strong> {certificate.ExpirationDate}<br />
          </li>
        ))}
      </ul> */}
      </div>
      </div>
    </div>
  );
}

export default CertificateList;
