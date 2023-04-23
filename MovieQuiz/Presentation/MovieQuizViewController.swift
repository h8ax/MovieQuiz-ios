//
//  MovieQuizViewController.swift
//  MovieQuiz
//
//  Created by H8AX on 14.04.2023.
//

import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var textView: UILabel!
    @IBOutlet private var counterView: UILabel!
    @IBOutlet private var imageView: UIImageView!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    private var presenter: MovieQuizPresenter!

        override func viewDidLoad() {
            super.viewDidLoad()

            imageView.layer.cornerRadius = 20
            presenter = MovieQuizPresenter(viewController: self)
        }
    
    //MARK: - Actions
    
    
    @IBAction func yesButtonClicked(_ sender: UIButton) {
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.noButtonClicked()
        
    }
    
    // MARK: - MovieQuizViewControllerProtocol
        
        func show(quiz step: QuizStepViewModel) {
            imageView.layer.borderColor = UIColor.clear.cgColor
            imageView.image = step.image
            textView.text = step.text
            counterView.text = step.questionNumber
        }
        
        func show(quiz result: QuizResultViewModel) {
            let message = presenter.makeResultsMessage()
            
            let alertModel = UIAlertController(
                title: result.title,
                message: message,
                preferredStyle: .alert)
            
            let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                self.presenter.restartGame()
            }
            
            alertModel.addAction(action)
            self.present(alertModel, animated: true, completion: nil)
        }
        
        func highlightImageBorder(isCorrectAnswer: Bool) {
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = 8
            imageView.layer.borderColor = isCorrectAnswer ? UIColor.systemGreen.cgColor : UIColor.systemRed.cgColor
        }
        
        func showLoadingIndicator() {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        }
        
        func hideLoadingIndicator() {
            activityIndicator.isHidden = true
        }
        
        func showNetworkError(message: String) {
            hideLoadingIndicator()
            
            let alert = UIAlertController(
                title: "Ошибка",
                message: message,
                preferredStyle: .alert)
            
            let action = UIAlertAction(title: "Попробовать ещё раз",
                                       style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                self.presenter.restartGame()
            }
            
            alert.addAction(action)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
