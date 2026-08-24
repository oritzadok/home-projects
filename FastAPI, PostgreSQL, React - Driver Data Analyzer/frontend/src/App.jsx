import React, { useState } from 'react';
import './App.css'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export default function App() {
  const [file, setFile] = useState(null);
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file) return alert("Please select a CSV file");

    setLoading(true);

    // Set the file name as session ID for now
    const sessionId = file.name.replace(".csv", "");

    const formData = new FormData();
    formData.append("file", file);
    formData.append("session_id", sessionId);

    try {
      // Upload to backend
      await fetch(`http://localhost:8000/api/upload?session_id=${sessionId}`, {
        method: "POST",
        body: formData,
      });

      // Fetch the cleaned data back for visualization
      const response = await fetch(`http://localhost:8000/api/sessions/${sessionId}/data`);
      const cleanData = await response.json();

      // Format timestamps for the chart
      const chartData = cleanData.map(d => ({
        ...d,
        time: new Date(d.timestamp).toLocaleTimeString()
      }));

      setData(chartData);
    } catch (error) {
      console.error("Error:", error);
      alert("Something went wrong check console");
    }
    setLoading(false);
  };

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif', maxWidth: '1200px', margin: '0 auto' }}>
      <h1>Telemetry Dashboard</h1>

      <div style={{ background: '#f5f5f5', padding: '1rem', borderRadius: '8px', marginBottom: '2rem' }}>
        <h3>Ingest New Session</h3>
        <form onSubmit={handleUpload}>
          <input
            type="file"
            accept=".csv"
            onChange={(e) => setFile(e.target.files[0])}
            style={{ marginRight: '1rem' }}
          />
          <button type="submit" disabled={loading} style={{ padding: '0.5rem 1rem', cursor: 'pointer' }}>
            {loading ? "Processing ETL Pipeline..." : "Upload & Process Data"}
          </button>
        </form>
      </div>

      {data.length > 0 && (
        <div>
          {/*<div style={{ background: '#fff3cd', padding: '1rem', borderLeft: '5px solid #ffc107', marginBottom: '2rem' }}>*/}
          {/*  <strong>Session Metadata Notes:</strong> Load session notes from SessionMeta table*/}
          {/*</div>*/}

          <h2>Speed vs. Wheel Angle Over Time</h2>
          <div style={{ width: '100%', height: 400, background: 'white', padding: '1rem', border: '1px solid #ddd', borderRadius: '8px' }}>
            <ResponsiveContainer>
              <LineChart data={data}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="time" />
                <YAxis yAxisId="left" label={{ value: 'Speed', angle: -90, position: 'insideLeft' }} />
                <YAxis yAxisId="right" orientation="right" label={{ value: 'Angle', angle: 90, position: 'insideRight' }} />
                <Tooltip />
                <Legend />
                <Line yAxisId="left" type="monotone" dataKey="speed" stroke="#2563eb" dot={false} strokeWidth={2} name="Speed (OBD2)" />
                <Line yAxisId="right" type="monotone" dataKey="wheel_angle" stroke="#dc2626" dot={false} strokeWidth={2} name="Wheel Angle" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}
    </div>
  );
}