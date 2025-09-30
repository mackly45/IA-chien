from django.core.management.base import BaseCommand
from ml_models.advanced_trainer import AdvancedTrainer
import logging

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Run advanced training for the dog breed identification model'

    def add_arguments(self, parser):
        parser.add_argument(
            '--epochs',
            type=int,
            default=50,
            help='Number of epochs for training (default: 50)'
        )
        
        parser.add_argument(
            '--iterations',
            type=int,
            default=1,
            help='Number of training iterations (default: 1)'
        )
        
        parser.add_argument(
            '--continuous',
            action='store_true',
            help='Run continuous learning loop'
        )
        
        parser.add_argument(
            '--auto-collect',
            action='store_true',
            help='Automatically collect data for all breeds with high quality'
        )
        
        parser.add_argument(
            '--quality-threshold',
            type=float,
            default=0.85,
            help='Quality threshold for data collection (default: 0.85)'
        )

    def handle(self, *args, **options):
        epochs = options['epochs']
        iterations = options['iterations']
        continuous = options['continuous']
        auto_collect = options['auto_collect']
        quality_threshold = options['quality_threshold']
        
        self.stdout.write(
            self.style.SUCCESS(f'Starting advanced training with {epochs} epochs and {iterations} iterations')  # type: ignore[attr-defined]
        )
        
        if auto_collect:
            self.stdout.write(
                self.style.WARNING(f'Auto-collect enabled with quality threshold: {quality_threshold:.2%}')  # type: ignore[attr-defined]
            )
        
        try:
            trainer = AdvancedTrainer()
            
            if continuous:
                # Run continuous learning loop
                result = trainer.continuous_learning_loop(
                    iterations=iterations,
                    hours_between_sessions=1,  # Short interval for testing
                    auto_collect=auto_collect,
                    quality_threshold=quality_threshold
                )
                
                if result["success"]:
                    self.stdout.write(
                        self.style.SUCCESS(  # type: ignore[attr-defined]
                            f'Continuous learning completed successfully! '
                            f'Overall improvement: {result["overall_improvement"]:.2%}'
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.ERROR(  # type: ignore[attr-defined]
                            f'Continuous learning failed: {result.get("error", "Unknown error")}'
                        )
                    )
            else:
                # Run intensive training sessions
                for i in range(iterations):
                    self.stdout.write(
                        self.style.WARNING(f'Starting training iteration {i+1}/{iterations}')  # type: ignore[attr-defined]
                    )
                    
                    result = trainer.intensive_training_session(
                        epochs=epochs,
                        auto_collect=auto_collect,
                        quality_threshold=quality_threshold
                    )
                    
                    if result["success"]:
                        self.stdout.write(
                            self.style.SUCCESS(  # type: ignore[attr-defined]
                                f'Iteration {i+1} completed successfully! '
                                f'Accuracy: {result["final_accuracy"]:.2%} '
                                f'(improvement: {result["improvement"]:.2%})'
                            )
                        )
                    else:
                        self.stdout.write(
                            self.style.ERROR(  # type: ignore[attr-defined]
                                f'Iteration {i+1} failed: {result.get("error", "Unknown error")}'
                            )
                        )
                        
            # Display final statistics
            stats = trainer.get_advanced_training_stats()
            self.stdout.write(
                self.style.SUCCESS(  # type: ignore[attr-defined]
                    f'Training completed. Total images: {stats.get("total_images", 0)}, '
                    f'Breeds: {stats.get("breeds_count", 0)}'
                )
            )
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f'Error during advanced training: {str(e)}')  # type: ignore[attr-defined]
            )
            raise e