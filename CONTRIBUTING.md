# Contributing to PT XYZ Data Warehouse

Thank you for your interest in contributing to the PT XYZ Data Warehouse project! This document provides guidelines and instructions for contributors.

## 📋 Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Code Guidelines](#code-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Testing](#testing)
- [Documentation](#documentation)

## 🚀 Getting Started

### Prerequisites

- Docker and Docker Compose
- Python 3.8+
- Git
- Basic knowledge of SQL and data warehousing concepts

### First Time Setup

1. **Fork the repository**
   ```bash
   git clone https://github.com/yourusername/DW_Project_Kelompok22.git
   cd DW_Project_Kelompok22
   ```

2. **Set up environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Start the development environment**
   ```bash
   docker-compose up -d
   ```

4. **Verify installation**
   ```bash
   ./test.sh
   ```

## 🛠️ Development Setup

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow the code guidelines below
   - Add tests for new functionality
   - Update documentation

3. **Test your changes**
   ```bash
   # Run ETL tests
   python test_etl.py
   
   # Run dashboard tests
   python test_dashboard_queries.py
   
   # Test Docker services
   ./test.sh
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add new dashboard feature"
   git push origin feature/your-feature-name
   ```

### Environment Management

- **Development**: Use `.env` for local development
- **Testing**: Use `.env.test` for automated testing
- **Production**: Use environment variables or Docker secrets

## 📝 Code Guidelines

### Python Code Style

- Follow PEP 8 style guidelines
- Use meaningful variable and function names
- Add docstrings to all functions and classes
- Maximum line length: 100 characters

**Example:**
```python
def load_dimension_table(connection, table_name, data):
    """
    Load data into a dimension table.
    
    Args:
        connection: Database connection object
        table_name (str): Name of the target table
        data (list): List of records to insert
        
    Returns:
        int: Number of records inserted
        
    Raises:
        DatabaseError: If insertion fails
    """
    # Implementation here
```

### SQL Code Style

- Use uppercase for SQL keywords
- Use meaningful table and column aliases
- Indent subqueries and JOINs consistently
- Comment complex queries

**Example:**
```sql
SELECT 
    dt.date AS time,
    eq.equipment_type,
    AVG(
        CAST(feu.operating_hours AS FLOAT) / 
        (feu.operating_hours + feu.downtime_hours) * 100
    ) AS efficiency
FROM fact.FactEquipmentUsage feu
JOIN dim.DimTime dt ON feu.time_key = dt.time_key
JOIN dim.DimEquipment eq ON feu.equipment_key = eq.equipment_key
WHERE dt.date >= DATEADD(day, -30, GETDATE())
GROUP BY dt.date, eq.equipment_type
ORDER BY dt.date;
```

### Docker Guidelines

- Use multi-stage builds when possible
- Pin specific image versions
- Include health checks
- Minimize layer count
- Use .dockerignore files

## 📬 Commit Messages

Use the [Conventional Commits](https://www.conventionalcommits.org/) specification:

### Format
```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples
```bash
feat(etl): add production data validation
fix(dashboard): correct equipment efficiency calculation
docs(readme): update installation instructions
test(etl): add unit tests for dimension loading
```

## 🔄 Pull Request Process

### Before Submitting

1. **Ensure tests pass**
   ```bash
   python test_etl.py
   python test_dashboard_queries.py
   ```

2. **Update documentation**
   - Update README.md if needed
   - Add inline code comments
   - Update API documentation

3. **Check security**
   - No hardcoded passwords or secrets
   - Follow security best practices
   - Review sensitive data handling

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots/Logs
Include relevant screenshots or log outputs

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
```

## 🧪 Testing

### Test Categories

1. **Unit Tests**: Test individual functions
   ```bash
   python -m pytest tests/unit/
   ```

2. **Integration Tests**: Test component interactions
   ```bash
   python test_etl.py
   ```

3. **Dashboard Tests**: Test visualization queries
   ```bash
   python test_dashboard_queries.py
   ```

4. **End-to-End Tests**: Test complete workflows
   ```bash
   ./test.sh
   ```

### Writing Tests

- Test both success and failure cases
- Use meaningful test names
- Include setup and teardown
- Mock external dependencies

**Example:**
```python
def test_load_equipment_dimension():
    """Test successful loading of equipment dimension data."""
    # Arrange
    test_data = [{'equipment_id': 1, 'equipment_type': 'Excavator'}]
    
    # Act
    result = load_dimension_table(connection, 'DimEquipment', test_data)
    
    # Assert
    assert result == 1
    assert_equipment_exists_in_db(1)
```

## 📚 Documentation

### Types of Documentation

1. **Code Documentation**: Inline comments and docstrings
2. **API Documentation**: Function and class documentation
3. **User Documentation**: README, setup guides
4. **Architecture Documentation**: System design documents

### Documentation Standards

- Use clear, concise language
- Include examples where helpful
- Keep documentation up-to-date with code changes
- Use markdown formatting for consistency

### Documentation Structure

```
docs/
├── api/              # API documentation
├── architecture/     # System design docs
├── deployment/       # Deployment guides
├── development/      # Development setup
└── user/            # User guides
```

## 🔒 Security Guidelines

### Sensitive Data

- Never commit passwords, API keys, or tokens
- Use environment variables for configuration
- Implement proper access controls
- Regular security audits

### Code Security

- Validate all inputs
- Use parameterized queries
- Implement proper error handling
- Follow OWASP guidelines

## 🐛 Issue Reporting

### Bug Reports

Include:
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details
- Relevant logs/screenshots

### Feature Requests

Include:
- Use case description
- Proposed solution
- Alternative approaches considered
- Impact assessment

## 📞 Getting Help

- **Documentation**: Check README.md and docs/
- **Issues**: Search existing GitHub issues
- **Discussions**: Use GitHub Discussions for questions
- **Code Review**: Request reviews for complex changes

## 🎯 Project Structure

Understanding the project structure helps with contributions:

```
DW_Project_Kelompok22/
├── airflow/          # ETL orchestration
├── dags/            # Airflow DAGs
├── Dataset/         # Sample data
├── grafana/         # Visualization configs
├── init-scripts/    # Database setup
├── notebooks/       # Analysis notebooks
├── docs/           # Documentation
└── tests/          # Test files
```

## 🏆 Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to PT XYZ Data Warehouse! 🚀
