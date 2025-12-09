const express = require('express');
const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(express.json());

// Health endpoints
app.get('/health', (req, res) => {
    res.json({ 
        status: 'UP', 
        service: 'nodejs-service',
        timestamp: new Date().toISOString()
    });
});

app.get('/ready', (req, res) => {
    res.json({ 
        status: 'READY',
        ready: true 
    });
});

// Simple API endpoints
app.get('/', (req, res) => {
    res.json({
        message: 'Welcome to Node.js Service',
        endpoints: [
            '/health',
            '/ready',
            '/api/users',
            '/api/items'
        ]
    });
});

app.get('/api/users', (req, res) => {
    res.json({
        users: [
            { id: 1, name: 'Alice', email: 'alice@example.com' },
            { id: 2, name: 'Bob', email: 'bob@example.com' },
            { id: 3, name: 'Charlie', email: 'charlie@example.com' }
        ]
    });
});

app.get('/api/items', (req, res) => {
    res.json({
        items: [
            { id: 1, name: 'Item 1', price: 10.99 },
            { id: 2, name: 'Item 2', price: 20.49 },
            { id: 3, name: 'Item 3', price: 5.99 }
        ]
    });
});

// Environment endpoint
app.get('/api/env', (req, res) => {
    res.json({
        nodeVersion: process.version,
        platform: process.platform,
        memoryUsage: process.memoryUsage(),
        env: process.env.NODE_ENV || 'development'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(port, () => {
    console.log(`Node.js service running on port ${port}`);
});