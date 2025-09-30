class DatabaseRouter:
    """
    A router to control all database operations on models
    """
    
    route_app_labels = {'classifier'}

    def db_for_read(self, model, **hints):
        """
        Attempts to read auth and contenttypes models go to mysql.
        """
        if model._meta.app_label in self.route_app_labels:
            return 'mysql'
        return 'default'

    def db_for_write(self, model, **hints):
        """
        Attempts to write auth and contenttypes models go to mysql.
        """
        if model._meta.app_label in self.route_app_labels:
            return 'mysql'
        return 'default'

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations if models are in the same app
        """
        db_set = {'default', 'mysql'}
        if obj1._state.db in db_set and obj2._state.db in db_set:
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        Make sure the auth and contenttypes apps only appear in the 'mysql' database.
        """
        if app_label in self.route_app_labels:
            return db == 'mysql'
        elif db == 'default':
            return True
        return None