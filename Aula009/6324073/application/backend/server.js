const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Mock database
const projects = [
    { id: 1, name: "Project AWS Deployment", description: "Deploying a full stack app on EC2 with VPC security." },
    { id: 2, name: "Infra as Code Lab", description: "Automating AWS resources using Shell Scripts and AWS CLI." }
];

// Health Check Endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'UP', timestamp: new Date(), ra: '6324073' });
});

// API Routes
app.get('/api/projects', (req, res) => {
    console.log('GET /api/projects - Projects requested');
    res.json(projects);
});

app.listen(port, () => {
    console.log(`Backend API listening at http://localhost:${port}`);
});
