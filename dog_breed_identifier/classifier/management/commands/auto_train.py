import logging
from django.core.management.base import BaseCommand
from ml_models.auto_trainer import AutoTrainer
from ml_models.data_manager import DataManager

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Entraîne automatiquement le modèle avec de nouvelles données'

    def add_arguments(self, parser):
        parser.add_argument(
            '--images-per-breed',
            type=int,
            default=5,
            help='Nombre d\'images à collecter par race (par défaut: 5)'
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force l\'entraînement même si les conditions ne sont pas remplies'
        )

    def handle(self, *args, **options):
        images_per_breed = options['images_per_breed']
        force = options['force']
        
        self.stdout.write(
            'Démarrage de l\'entraînement automatique...'
        )
        
        try:
            # Initialiser l'entraîneur automatique
            trainer = AutoTrainer()
            
            # Vérifier si l'entraînement est nécessaire
            if not force and not trainer.should_train():
                self.stdout.write(
                    'Aucun entraînement nécessaire pour le moment.'
                )
                return
            
            # Collecter de nouvelles données
            self.stdout.write(
                f'Collecte de {images_per_breed} images par race...'
            )
            trainer.collect_new_data(num_images_per_breed=images_per_breed)
            
            # Valider le dataset
            self.stdout.write(
                'Validation du dataset...'
            )
            data_manager = DataManager()
            validation_report = data_manager.validate_dataset()
            
            if validation_report.get('issues'):
                self.stdout.write(
                    'Problèmes détectés dans le dataset:'
                )
                for issue in validation_report['issues']:
                    self.stdout.write(f'  - {issue}')
            
            # Entraîner le modèle
            self.stdout.write(
                'Entraînement du modèle...'
            )
            result = trainer.train_model()
            
            if result["success"]:
                self.stdout.write(
                    f'Entraînement réussi! Précision: {result["accuracy"]:.2%}'
                )
                
                # Afficher les statistiques
                stats = trainer.get_training_stats()
                self.stdout.write(
                    f'Total images: {stats.get("total_images", 0)}'
                )
                self.stdout.write(
                    f'Nombre de races: {stats.get("breeds_count", 0)}'
                )
            else:
                self.stdout.write(
                    f'Échec de l\'entraînement: {result.get("error", "Erreur inconnue")}'
                )
                
        except Exception as e:
            self.stdout.write(
                f'Erreur lors de l\'entraînement: {str(e)}'
            )
            logger.error(f'Erreur lors de l\'entraînement automatique: {e}', exc_info=True)