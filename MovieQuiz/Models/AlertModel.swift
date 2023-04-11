//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by H8AX on 10.04.2023.
//

import Foundation

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: (() -> Void)
}
