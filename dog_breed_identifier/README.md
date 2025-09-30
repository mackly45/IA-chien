# Dog Breed Identifier

A Django web application that uses machine learning to identify dog breeds and their countries of origin from uploaded images.

## Features

- Upload dog photos for breed identification
- AI-powered breed and origin detection
- Detailed breed information database
- Responsive web interface

## Technologies Used

- **Django**: Web framework for Python
- **TensorFlow/Keras**: Machine learning framework
- **HTML/CSS/Bootstrap**: Frontend design
- **SQLite**: Database for development

## Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   ```

2. Navigate to the project directory:
   ```
   cd dog_breed_identifier
   ```

3. Create a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

4. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

5. Run database migrations:
   ```
   python manage.py migrate
   ```

6. Create a superuser (optional):
   ```
   python manage.py createsuperuser
   ```

7. Run the development server:
   ```
   python manage.py runserver
   ```

8. Visit `http://127.0.0.1:8000` in your browser

## Project Structure

```
dog_breed_identifier/
├── classifier/              # Main Django app
│   ├── models.py           # Database models
│   ├── views.py            # View functions
│   ├── urls.py             # URL routing
│   └── templates/          # HTML templates
├── dog_identifier/         # Django project settings
├── ml_models/              # Machine learning models
├── static/                 # Static files (CSS, JS, images)
├── templates/              # Base templates
├── manage.py              # Django management script
└── requirements.txt       # Python dependencies
```

## Machine Learning Model

The application uses a convolutional neural network (CNN) trained on the Stanford Dogs Dataset to identify dog breeds. The model can identify over 120 different dog breeds and their countries of origin.

## Database Models

1. **DogBreed**: Stores information about dog breeds
   - Name
   - Origin country
   - Description

2. **UploadedImage**: Stores uploaded images and prediction results
   - Image file
   - Upload timestamp
   - Predicted breed (foreign key)
   - Confidence score

## Future Improvements

- Implement a more sophisticated CNN model
- Add more dog breeds to the database
- Improve the user interface with additional features
- Add user accounts and image history
- Implement batch processing for multiple images

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Stanford Dogs Dataset for providing the training data
- Django and TensorFlow communities for excellent documentation