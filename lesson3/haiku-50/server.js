require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Haiku 50 server running');
});

app.listen(PORT, () => {
  console.log(`Haiku 50 server running on port ${PORT}`);
});
