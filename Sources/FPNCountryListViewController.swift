//
//  FPNCountryListViewController.swift
//  FlagPhoneNumber
//
//  Created by Aurélien Grifasi on 06/08/2017.
//  Copyright (c) 2017 Aurélien Grifasi. All rights reserved.
//

import UIKit

class CountryTableViewCell: UITableViewCell {
    let countryLabel: UILabel = {
        let title = UILabel()
        title.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        title.textColor = UIColor(red: 195 / 255.0, green: 195 / 255.0, blue: 195 / 255.0, alpha: 1.0)
        return title
    }()
    
    let phoneCodeLabel: UILabel = {
        let title = UILabel()
        title.textAlignment = .right
        title.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return title
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        backgroundView = nil
        selectedBackgroundView = nil
        addSubview(countryLabel)
        addSubview(phoneCodeLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        countryLabel.frame = .init(
            x: 16,
            y: 0,
            width: frame.width - 16,
            height: frame.height
        )
        
        phoneCodeLabel.frame = .init(
            x: 0,
            y: 0,
            width: frame.width - 16,
            height: frame.height
        )
    }
    
    func bind(
        _ country: FPNCountry,
        shouldShowPhoneCode: Bool,
        cellTextColor: UIColor,
        cellTextFont: UIFont
    ) {
        countryLabel.font = cellTextFont
        countryLabel.textColor = cellTextColor
        countryLabel.text = country.name

        if shouldShowPhoneCode {
            phoneCodeLabel.font = cellTextFont
            phoneCodeLabel.textColor = cellTextColor
            phoneCodeLabel.text = country.phoneCode
        }
    }
}

open class FPNCountryListViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate {

	open var repository: FPNCountryRepository?
	open var showCountryPhoneCode: Bool = true
    open var tableBackgroundColor: UIColor = .white
    open var cellHighlightColor: UIColor = UIColor.lightGray.withAlphaComponent(0.1)
    open var cellHeight: CGFloat = 45
    open var cellTextColor = UIColor(red: 195 / 255.0, green: 195 / 255.0, blue: 195 / 255.0, alpha: 1.0)
    open var cellTextFont = UIFont.systemFont(ofSize: 17, weight: .medium)
	open var searchController: UISearchController = UISearchController(searchResultsController: nil)
	open var didSelect: ((FPNCountry) -> Void)?

	var results: [FPNCountry]?

	override open func viewDidLoad() {
		super.viewDidLoad()
        tableView.register(CountryTableViewCell.self, forCellReuseIdentifier: "CountryTableViewCell")
		tableView.tableFooterView = UIView()

		initSearchBarController()
        tableView.backgroundColor = tableBackgroundColor
	}

	open func setup(repository: FPNCountryRepository) {
		self.repository = repository
	}

	private func initSearchBarController() {
		searchController.searchResultsUpdater = self
		searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false

		if #available(iOS 11.0, *) {
			navigationItem.searchController = searchController
			navigationItem.hidesSearchBarWhenScrolling = false
		} else {
			searchController.dimsBackgroundDuringPresentation = false
			searchController.hidesNavigationBarDuringPresentation = true
			searchController.definesPresentationContext = true

			//				searchController.searchBar.sizeToFit()
			tableView.tableHeaderView = searchController.searchBar
		}
		definesPresentationContext = true
	}

	private func getItem(at indexPath: IndexPath) -> FPNCountry {
		if searchController.isActive && results != nil && results!.count > 0 {
			return results![indexPath.row]
		} else {
			return repository!.countries[indexPath.row]
		}
	}

	override open func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if searchController.isActive {
			if let count = searchController.searchBar.text?.count, count > 0 {
				return results?.count ?? 0
			}
		}
		return repository?.countries.count ?? 0
	}

	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CountryTableViewCell", for: indexPath) as! CountryTableViewCell
		
		let country = getItem(at: indexPath)
        cell.bind(
            country,
            shouldShowPhoneCode: showCountryPhoneCode,
            cellTextColor: cellTextColor,
            cellTextFont: cellTextFont
        )

		return cell
	}

	override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let country = getItem(at: indexPath)

		tableView.deselectRow(at: indexPath, animated: true)

		didSelect?(country)

        if searchController.isActive {
            searchController.isActive = false
            searchController.searchBar.resignFirstResponder()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.closeViewController()
            }
        } else {
            closeViewController()
        }
	}
    
    private func closeViewController() {
        if navigationController == nil {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    open override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.backgroundColor = cellHighlightColor
    }
    
    open override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.backgroundColor = tableBackgroundColor
    }
    
    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }

	// UISearchResultsUpdating

	open func updateSearchResults(for searchController: UISearchController) {
		guard let countries = repository?.countries else { return }

		if countries.isEmpty {
			results?.removeAll()
			return
		} else if searchController.searchBar.text == "" {
			results?.removeAll()
			tableView.reloadData()
			return
		}

		if let searchText = searchController.searchBar.text, searchText.count > 0 {
			results = countries.filter({(item: FPNCountry) -> Bool in
				if item.name.lowercased().range(of: searchText.lowercased()) != nil {
					return true
				} else if item.code.rawValue.lowercased().range(of: searchText.lowercased()) != nil {
					return true
				} else if item.phoneCode.lowercased().range(of: searchText.lowercased()) != nil {
					return true
				}
				return false
			})
		}
		tableView.reloadData()
	}

	// UISearchControllerDelegate

	open func willDismissSearchController(_ searchController: UISearchController) {
		results?.removeAll()
	}
    
    deinit {
        debugPrint("Deinit FPNCountryListViewController")
    }
}
