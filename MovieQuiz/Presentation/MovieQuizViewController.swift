//
//  MovieQuizViewController.swift
//  MovieQuiz
//
//  Created by H8AX on 14.04.2023.
//

import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    func didFailToLoadQuestion(with error: Error) {
        let alertController = UIAlertController(title: "Ошибка", message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "ОК", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }

    
    
    
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var textView: UILabel!
    @IBOutlet private var counterView: UILabel!
    @IBOutlet private var imageView: UIImageView!
    
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    private var correctAnswear: Int = 0
    private var currentQuestionIndex: Int = 0
    
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    
    private var alertPresent: AlertPresenter?
    private var statisticService: StatisticService?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 20
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(),delegate: self)
        alertPresent = AlertPresenter(viewController: self)
        statisticService = StatisticServiceImplementation()
        
        activityIndicator.hidesWhenStopped = true
        
        showLoadingIndicator()
        questionFactory?.loadData()
    }
    
    // MARK: - QuestionFactoryDelegate
    
    private func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    
    private func showNetworkError(message: String) {
        DispatchQueue.main.async { [weak self] in
            let alertModel = AlertModel(
                title: "Ошибка",
                message: message,
                buttonText: "Попробовать еще раз") { [weak self] in
                    guard let self = self else { return }
                    self.currentQuestionIndex = 0
                    self.correctAnswear = 0
                    self.questionFactory?.requestNextQuestion()
                }
            self?.alertPresent?.show(alertModel: alertModel)
        }
    }

    func presentErrorAlert(with message: String) {
        let alertController = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "Повторить", style: .default) { [weak self] _ in
            self?.questionFactory?.loadData()
        }
        alertController.addAction(retryAction)
        present(alertController, animated: true, completion: nil)
    }


    
    func didLoadDataFromServer() {
        hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }

    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription)
    }
    

    func didReceiveNextQuestion(question: QuizQuestion?) {
        self.currentQuestion = question
        let viewModel = self.convert(model: question ?? question!)
        self.show(quize: viewModel)
        self.hideLoadingIndicator()
    }
    
    func didFinishQuiz() {
        statisticService?.store(correct: correctAnswear, total: questionsAmount)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func show(quize step: QuizStepViewModel){
        imageView.layer.borderColor=UIColor.clear.cgColor
        imageView.image = step.image
        textView.text = step.text
        counterView.text = step.questionNumber
    }
    
private func show(quiz result: QuizResultViewModel) {
        statisticService?.store(correct: 1, total: 1)
        
        let alertModel = AlertModel(
            title: "",
            message: "",
            buttonText: "",
            completion: { [weak self] in
                self?.currentQuestionIndex = 0
                self?.correctAnswear = 0
                self?.questionFactory?.requestNextQuestion()
                
            }
        )
    
        alertPresent?.show(alertModel: alertModel)
        
    }


    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            text: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        noButton.isEnabled = false
        yesButton.isEnabled = false
        if isCorrect {
            correctAnswear += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
            self.showNextQuestionOrResults()
        }
    }
    
    private func showNextQuestionOrResults() {
        yesButton.isEnabled = true
        noButton.isEnabled = true
        if currentQuestionIndex == questionsAmount - 1 {
            showFinalResult()
        } else {
            currentQuestionIndex += 1 
            questionFactory?.requestNextQuestion()
        }
    }
    
    private func showFinalResult() {
        statisticService?.store(correct: correctAnswear, total: questionsAmount)
        
        let alertModel = AlertModel(
            title: "Этот раунд окончен!",
            message: makeResultMessage(),
            buttonText: "Сыграть еще раз",
            completion: { [weak self] in
                self?.currentQuestionIndex = 0
                self?.correctAnswear = 0
                self?.questionFactory?.requestNextQuestion()
                
            }
        )
        alertPresent?.show(alertModel: alertModel)
    }
    
    private func makeResultMessage() -> String {
        
        guard let statisticService = statisticService else {
            return "Пока рекордов нет"
        }
        
        let accuracy = String(format: "%.2f" , statisticService.totalAccuracy)
        let totalPlaysCountLine = """
        Количество сыгранных квизов: \(statisticService.gamesCount)
        """
        let currentGameResult = """
        Ваш результат: \(correctAnswear)\\\(questionsAmount)
        """
        var bestGameInfoLine = ""
        if let gameRecord = statisticService.gameRecord {
            bestGameInfoLine = "Рекорд: \(gameRecord.correct)\\\(gameRecord.total)"
            + "(\(gameRecord.date.dateTimeString))"
        }
        let averageAccuaryLine = "Cредняя точность: \(accuracy)%"
        
        let resultMessage = [
            currentGameResult, totalPlaysCountLine, bestGameInfoLine, averageAccuaryLine].joined(separator: "\n")
        
       return resultMessage
    }
    
    @IBAction func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
}
