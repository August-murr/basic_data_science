# Fine-Tuning Machine Translation Model for Movie Parallel Subtitle Translation with PEFT

In this Jupyter Notebook, I've utilized Hugging Face's libraries to fine-tune a machine translation model using the [Movie Parallel Subtitles Dataset](https://www.kaggle.com/datasets/augustmurr/movie-parallel-dataset), which I collected myself.

## Dataset Overview

The dataset consists of two types of parallel data: line-by-line data and time-based data. While the default model performs well in translating line-by-line data, it struggles with longer sequences and often fails to replicate the extended structure of the translated data. To address this, I opted to fine-tune a model on the time-based dataset.

The dataset includes four language pairs, and I selected "English to Thai" since the original model appeared to perform the least effectively on that pair. Possible reasons for this may include the limited availability of English to Thai data and the complexity of the Thai language compared to the languages the model is more familiar with.

## Model and Training Strategy

The model is a transformer with over 600 million parameters. Given the constraints of using Google Colab's free GPU, full fine-tuning was not a viable option. To overcome this limitation, I employed the Parameter-Efficient Fine-Tuning (PEFT) library by Hugging Face and utilized a LORA (Low-Rank Adapter) to train the model.

Additionally, I converted all the weights from 32-bit floats to 16-bit floats, significantly reducing the required computing power without a substantial performance drop. This not only enhances efficiency but also helps prevent catastrophic forgetting.

## Customization and Adaptability

With just a few lines of changes in the notebook, you can train an adapter for a different language pair or a different dataset, adjusting the sizes of adapters as needed.

---


