import { createApp } from "./app.js";

const port = Number(process.env.PORT ?? 4300);
const app = createApp();

app.listen(port, () => {
  console.log(`qualimetry server listening on http://localhost:${port}`);
});
