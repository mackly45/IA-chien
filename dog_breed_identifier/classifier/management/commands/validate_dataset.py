from django.core.management.base import BaseCommand
from ml_models.data_manager import DataManager
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Validate and clean the dog breed dataset'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clean',
            action='store_true',
            help='Clean the dataset by removing invalid images'
        )
        
        parser.add_argument(
            '--balance',
            action='store_true',
            help='Balance the dataset by augmenting underrepresented breeds'
        )
        
        parser.add_argument(
            '--export',
            type=str,
            help='Export dataset information to a file'
        )

    def handle(self, *args, **options):
        clean = options['clean']
        balance = options['balance']
        export_file = options['export']
        
        self.stdout.write(
            self.style.SUCCESS('Starting dataset validation...')  # type: ignore[attr-defined]
        )
        
        try:
            data_manager = DataManager()
            
            # Validate the dataset
            validation_report = data_manager.validate_dataset()
            
            if "error" in validation_report:
                self.stdout.write(
                    self.style.ERROR(f'Validation failed: {validation_report["error"]}')  # type: ignore[attr-defined]
                )
                return
            
            # Display validation results
            self.stdout.write(
                self.style.SUCCESS(  # type: ignore[attr-defined]
                    f'Dataset validation completed:\n'
                    f'  Total breeds: {validation_report["total_breeds"]}\n'
                    f'  Total images: {validation_report["total_images"]}\n'
                    f'  Issues found: {len(validation_report["issues"])}'
                )
            )
            
            if validation_report["issues"]:
                self.stdout.write(
                    self.style.WARNING('Issues found:')  # type: ignore[attr-defined]
                )
                for issue in validation_report["issues"][:10]:  # Show first 10 issues
                    self.stdout.write(f'  - {issue}')
                if len(validation_report["issues"]) > 10:
                    self.stdout.write(f'  ... and {len(validation_report["issues"]) - 10} more issues')
            
            # Clean the dataset if requested
            if clean:
                self.stdout.write(
                    self.style.WARNING('Cleaning dataset...')  # type: ignore[attr-defined]
                )
                cleanup_report = data_manager.clean_dataset()
                
                if "error" in cleanup_report:
                    self.stdout.write(
                        self.style.ERROR(f'Cleanup failed: {cleanup_report["error"]}')  # type: ignore[attr-defined]
                    )
                else:
                    self.stdout.write(
                        self.style.SUCCESS(  # type: ignore[attr-defined]
                            f'Dataset cleaned successfully:\n'
                            f'  Invalid images removed: {cleanup_report["invalid_removed"]}\n'
                            f'  Duplicates removed: {cleanup_report["duplicates_removed"]}'
                        )
                    )
            
            # Balance the dataset if requested
            if balance:
                self.stdout.write(
                    self.style.WARNING('Balancing dataset...')  # type: ignore[attr-defined]
                )
                if data_manager.balance_dataset():
                    self.stdout.write(
                        self.style.SUCCESS('Dataset balanced successfully')  # type: ignore[attr-defined]
                    )
                else:
                    self.stdout.write(
                        self.style.ERROR('Failed to balance dataset')  # type: ignore[attr-defined]
                    )
            
            # Export dataset information if requested
            if export_file:
                self.stdout.write(
                    self.style.WARNING(f'Exporting dataset information to {export_file}...')  # type: ignore[attr-defined]
                )
                if data_manager.export_dataset_info(export_file):
                    self.stdout.write(
                        self.style.SUCCESS(f'Dataset information exported to {export_file}')  # type: ignore[attr-defined]
                    )
                else:
                    self.stdout.write(
                        self.style.ERROR(f'Failed to export dataset information')  # type: ignore[attr-defined]
                    )
            
            # Display breed statistics
            stats = data_manager.get_breed_statistics()
            if "error" not in stats:
                self.stdout.write(
                    self.style.SUCCESS(  # type: ignore[attr-defined]
                        f'\nTop 10 breeds by image count:'
                    )
                )
                for i, (breed, details) in enumerate(list(stats["breed_details"].items())[:10]):
                    self.stdout.write(
                        f'  {i+1:2d}. {breed:<30} {details["image_count"]:4d} images ({details["percentage"]:5.1f}%)'
                    )
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error during dataset validation: {str(e)}')  # type: ignore[attr-defined]
            )
            raise e