const express = require('express');
const app = express();

app.use(express.json()); // ОБЯЗАТЕЛЬНО, иначе req.body пустой

app.post('/convert', async (req, res) => {
  const markdown = req.body.markdown;

  if (!markdown) {
    return res.status(400).json({ error: 'Missing markdown' });
  }

  // Примитивная конвертация — заменишь на что-то реальное
  const html = markdown
    .replace(/^# (.*)$/gm, '<h1>$1</h1>')
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');

  res.json({
    id: 'test-id',
    html,
    status: 'completed'
  });
});

app.listen(3000, () => {
  console.log('Frontend API listening on port 3000');
});