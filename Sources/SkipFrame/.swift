//
//  MainViewController.swift
//  SkipFrame
//
//  Created by Скіп Юлія Ярославівна on 12.11.2025.
//

import UIKit

class MainViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let items = ["Перший", "Другий", "Третій", "Четвертий"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Список"
        setupTableView()
        setupNavBar()
    }

    private func setupNavBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addTapped))
    }

    @objc private func addTapped() {
        let alert = UIAlertController(title: "Додавання", message: "Це приклад alert", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Нова назва" }
        alert.addAction(UIAlertAction(title: "Скасувати", style: .cancel))
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
        })
        present(alert, animated: true)
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension MainViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    
}
