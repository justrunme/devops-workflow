const express = require('express');
const redis = require('redis');
const { promisify } = require('util');
const crypto = require('crypto');

const app = express();
app.use(express.json());

// Connect to Redis
const redisClient = redis.createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
redisClient.on('error', (err) => console.log('Redis Client Error', err));
redisClient.connect();

const getAsync = promisify(redisClient.get).bind(redisClient);
const setAsync = promisify(redisClient.set).bind(redisClient);

// Endpoint to submit markdown
app.post('/convert', async (req, res) => {
    const { markdown } = req.body;
    if (!markdown) {
        return res.status(400).send({ error: 'Markdown content is required' });
    }

    const taskId = crypto.randomBytes(16).toString('hex');
    const task = {
        id: taskId,
        status: 'pending',
        markdown: markdown,
        createdAt: new Date().toISOString()
    };

    await setAsync(taskId, JSON.stringify(task));

    res.status(202).send({ id: taskId });
});

// Endpoint to check status and get result
app.get('/result/:id', async (req, res) => {
    const taskId = req.params.id;
    const taskData = await getAsync(taskId);

    if (!taskData) {
        return res.status(404).send({ error: 'Task not found' });
    }

    const task = JSON.parse(taskData);
    res.send(task);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Frontend API listening on port ${PORT}`);
});
